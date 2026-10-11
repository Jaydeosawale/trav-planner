from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from app.database.session import SessionLocal
from app.integrations.llm.base import LLMResponse
from app.integrations.llm.factory import get_llm_provider
from app.services.ai.admin_billing_service import (
    AdminBillingService,
)
from app.services.ai.billing_policy import BillingPolicy
from app.services.ai.provider_manager import (
    ProviderDecision,
    ProviderManager,
)
from app.services.ai.quota_manager import QuotaManager
from app.services.ai.cost_calculator import (
    AICostCalculator,
)
from app.services.ai.pricing import (
    create_pricing_registry,
)

@dataclass
class AIGatewayResponse:
    """
    Result returned by the AI Gateway.
    """

    allowed: bool

    provider: str | None

    mode: str

    content: str = ""

    reason: str = ""

    reset_provider: str | None = None

    reset_minutes: int | None = None

    metadata: dict[str, Any] | None = None


class AIGateway:
    """
    Central AI gateway for Trav Planner.

    The Gateway is the ONLY layer that should decide whether
    an AI request may proceed.

    Decision order:

        1. Free provider
        2. Another free provider
        3. Admin billing permission
        4. Paid provider
        5. Otherwise block

    IMPORTANT:

    Agents should NOT directly select a paid provider.

    The provider factory only constructs providers.
    The Gateway decides whether construction/use is allowed.

    The Admin billing configuration is loaded from PostgreSQL
    before every AI request so that Admin changes take effect
    without restarting the application.
    """

    def __init__(
        self,
        *,
        quota_manager: QuotaManager | None = None,
        billing_policy: BillingPolicy | None = None,
        free_providers: list[str] | None = None,
        paid_provider: str | None = None,
        
    ) -> None:

        self.quota_manager = (
            quota_manager
            or QuotaManager()
        )

        self.billing_policy = (
            billing_policy
            or BillingPolicy()
        )

        self.free_providers = (
            free_providers
            or [
                "groq",
                "gemini",
            ]
        )

        self.paid_provider = paid_provider
        self.pricing_registry = (
            create_pricing_registry()
        )
        self.provider_manager = ProviderManager(
            quota_manager=self.quota_manager,
            billing_policy=self.billing_policy,
            free_providers=self.free_providers,
            paid_provider=self.paid_provider,
        )

    # ==========================================================
    # BILLING SYNCHRONIZATION
    # ==========================================================

    async def _refresh_billing_from_database(self) -> None:
        """
        Load the latest Admin-controlled billing configuration
        from PostgreSQL.

        This makes the Admin billing configuration the runtime
        source of truth.

        Safe default remains:

            paid_enabled = False
            mode = FREE_ONLY
        """

        service = AdminBillingService(
            billing_policy=self.billing_policy,
            paid_provider=(
                self.paid_provider
                or "groq"
            ),
        )

        async with SessionLocal() as db:

            state = await service.load_from_database(
                db
            )

        # ------------------------------------------------------
        # Synchronize Gateway state
        # ------------------------------------------------------

        self.billing_policy = service._policy

        self.paid_provider = (
            state.paid_provider
        )

        # ------------------------------------------------------
        # Synchronize ProviderManager
        # ------------------------------------------------------

        self.provider_manager.billing_policy = (
            self.billing_policy
        )

        self.provider_manager.paid_provider = (
            self.paid_provider
        )
    


         # ==========================================================
    # AI USAGE COST RECORDING
    # ==========================================================

    async def _record_response_cost(
        self,
        response: LLMResponse,
        *,
        billing_mode: str,
    ) -> None:
        """
        Calculate and persist the cost of a paid AI response.

        Free-provider requests are never charged.

        Ollama normally has zero configured API cost.

        Missing usage information results in zero calculated
        cost and is not persisted as spending.
        """

        # ------------------------------------------------------
        # FREE REQUEST
        # ------------------------------------------------------

        if billing_mode != "paid":
            return

        # ------------------------------------------------------
        # USAGE
        # ------------------------------------------------------

        usage = response.usage

        if not usage.has_usage:
            return

        # ------------------------------------------------------
        # PRICING
        # ------------------------------------------------------

        try:
            pricing = self.pricing_registry.get(
                provider=response.provider,
                model=response.model,
            )

        except KeyError as exc:
            raise RuntimeError(
                "No AI pricing configured for "
                f"provider='{response.provider}', "
                f"model='{response.model}'."
            ) from exc

        # ------------------------------------------------------
        # COST CALCULATION
        # ------------------------------------------------------

        cost = AICostCalculator.calculate(
            usage,
            pricing,
        )

        # ------------------------------------------------------
        # ZERO COST
        # ------------------------------------------------------

        if cost.total_cost <= 0:
            return

        # ------------------------------------------------------
        # PERSIST COST
        # ------------------------------------------------------

        service = AdminBillingService(
            billing_policy=self.billing_policy,
            paid_provider=(
                self.paid_provider
                or response.provider
            ),
        )

        async with SessionLocal() as db:

            await service.load_from_database(
                db
            )

            await service.record_usage_cost(
                db,
                amount=cost.total_cost,
                provider=response.provider,
                model=response.model,
            )



    # ==========================================================
    # PROVIDER DECISION
    # ==========================================================

    def decide(self) -> ProviderDecision:
        """
        Decide which provider is currently allowed.

        No LLM API request is made here.
        """

        return self.provider_manager.choose()

    # ==========================================================
    # REQUEST PERMISSION
    # ==========================================================

    async def check_request(self) -> AIGatewayResponse:
        """
        Check whether an AI request is currently allowed.

        This does NOT call an LLM.

        The latest billing configuration is loaded from
        PostgreSQL before making the decision.
        """

        await self._refresh_billing_from_database()

        decision = self.decide()

        if not decision.allowed:

            return AIGatewayResponse(
                allowed=False,
                provider=None,
                mode="blocked",
                reason=decision.reason,
                reset_provider=(
                    decision.reset_provider
                ),
                reset_minutes=(
                    decision.reset_minutes
                ),
                metadata={
                    "billing_enabled": (
                        self.billing_policy.paid_enabled
                    ),
                    "billing_mode": (
                        self.billing_policy.mode.value
                    ),
                    "paid_provider": (
                        self.paid_provider
                    ),
                },
            )

        return AIGatewayResponse(
            allowed=True,
            provider=decision.provider,
            mode=decision.mode,
            reason=decision.reason,
            reset_provider=(
                decision.reset_provider
            ),
            reset_minutes=(
                decision.reset_minutes
            ),
            metadata={
                "billing_enabled": (
                    self.billing_policy.paid_enabled
                ),
                "billing_mode": (
                    self.billing_policy.mode.value
                ),
                "paid_provider": (
                    self.paid_provider
                ),
            },
        )

    # ==========================================================
    # PROVIDER CREATION
    # ==========================================================

    def _create_provider(
        self,
        provider_name: str,
    ):
        """
        Create the provider selected by ProviderManager.

        This method is private to the Gateway so application
        agents cannot bypass the provider-selection policy.
        """

        return get_llm_provider(
            provider=provider_name
        )

    # ==========================================================
    # NORMAL TEXT GENERATION
    # ==========================================================

    async def generate(
        self,
        prompt: str,
        *,
        system_prompt: str | None = None,
        temperature: float = 0.2,
        max_output_tokens: int = 4096,
        **kwargs: Any,
    ) -> AIGatewayResponse:
        """
        Generate normal text through the selected provider.
        """

        permission = await self.check_request()

        # ------------------------------------------------------
        # BLOCKED
        # ------------------------------------------------------

        if not permission.allowed:

            return AIGatewayResponse(
                **{
                    **permission.__dict__,
                    "content": self.blocked_message(
                        permission
                    ),
                }
            )

        provider_name = permission.provider

        if not provider_name:
            raise RuntimeError(
                "Gateway allowed the request but no provider "
                "was selected."
            )

        provider = self._create_provider(
            provider_name
        )

        # ------------------------------------------------------
        # Execute provider
        # ------------------------------------------------------

        response: LLMResponse = await provider.generate(
            prompt,
            system_prompt=system_prompt,
            temperature=temperature,
            max_output_tokens=max_output_tokens,
            **kwargs,
        )

        await self._record_response_cost(
            response,
            billing_mode=permission.mode,
        )

        return AIGatewayResponse(
            allowed=True,
            provider=response.provider,
            mode=permission.mode,
            content=response.content,
            reason=permission.reason,
            reset_provider=(
                permission.reset_provider
            ),
            reset_minutes=(
                permission.reset_minutes
            ),
            metadata={
    "model": response.model,
    "billing_enabled": (
        self.billing_policy.paid_enabled
    ),
    "billing_mode": (
        self.billing_policy.mode.value
    ),
    "paid_provider": (
        self.paid_provider
    ),
},
        )

    # ==========================================================
    # TOOL CALLING
    # ==========================================================

    async def generate_with_tools(
        self,
        prompt: str,
        *,
        tools: list[dict[str, Any]],
        system_prompt: str | None = None,
        temperature: float = 0.2,
        max_output_tokens: int = 4096,
        **kwargs: Any,
    ) -> tuple[AIGatewayResponse, LLMResponse | None]:
        """
        Generate a tool-capable response through the Gateway.

        The current Admin billing configuration is loaded from
        PostgreSQL before provider selection.
        """

        permission = await self.check_request()

        # ------------------------------------------------------
        # BLOCKED
        # ------------------------------------------------------

        if not permission.allowed:

            blocked = AIGatewayResponse(
                **{
                    **permission.__dict__,
                    "content": self.blocked_message(
                        permission
                    ),
                }
            )

            return blocked, None

        provider_name = permission.provider

        if not provider_name:
            raise RuntimeError(
                "Gateway allowed the request but no provider "
                "was selected."
            )

        provider = self._create_provider(
            provider_name
        )

        response: LLMResponse = (
            await provider.generate_with_tools(
                prompt,
                tools=tools,
                system_prompt=system_prompt,
                temperature=temperature,
                max_output_tokens=max_output_tokens,
                **kwargs,
            )
        )
        await self._record_response_cost(
            response,
            billing_mode=permission.mode,
        )

        gateway_response = AIGatewayResponse(
            allowed=True,
            provider=response.provider,
            mode=permission.mode,
            content=response.content,
            reason=permission.reason,
            reset_provider=(
                permission.reset_provider
            ),
            reset_minutes=(
                permission.reset_minutes
            ),
            metadata={
                "model": response.model,
                "tool_calls": len(
                    response.tool_calls
                ),
                "billing_enabled": (
                    self.billing_policy.paid_enabled
                ),
                "billing_mode": (
                    self.billing_policy.mode.value
                ),
            },
        )

        return gateway_response, response

    # ==========================================================
    # TOOL RESULT CONTINUATION
    # ==========================================================

    async def continue_with_tool_results(
        self,
        *,
        response: LLMResponse,
        tool_results: list[dict[str, Any]],
        tools: list[dict[str, Any]],
        system_prompt: str | None = None,
        temperature: float = 0.2,
        max_output_tokens: int = 4096,
        **kwargs: Any,
    ) -> tuple[AIGatewayResponse, LLMResponse | None]:
        """
        Continue an LLM response after tools have executed.

        The continuation must use the SAME provider that
        produced the original tool call.
        """

        provider_name = response.provider

        if not provider_name:
            raise RuntimeError(
                "Original LLM response does not contain "
                "a provider name."
            )

        # ------------------------------------------------------
        # Refresh Admin billing state
        # ------------------------------------------------------

        permission = await self.check_request()

        if not permission.allowed:

            blocked = AIGatewayResponse(
                **{
                    **permission.__dict__,
                    "content": self.blocked_message(
                        permission
                    ),
                }
            )

            return blocked, None

        # ------------------------------------------------------
        # Original provider must still be permitted
        # ------------------------------------------------------

        if permission.provider != provider_name:

            raise RuntimeError(
                "The provider selected by the Gateway changed "
                "during an active tool-calling conversation. "
                f"Original provider: {provider_name}; "
                f"current provider: {permission.provider}."
            )

        provider = self._create_provider(
            provider_name
        )

        final_response: LLMResponse = (
            await provider.continue_with_tool_results(
                response=response,
                tool_results=tool_results,
                tools=tools,
                system_prompt=system_prompt,
                temperature=temperature,
                max_output_tokens=max_output_tokens,
                **kwargs,
            )
        )

        await self._record_response_cost(
            final_response,
            billing_mode=permission.mode,
        )

        gateway_response = AIGatewayResponse(
            allowed=True,
            provider=final_response.provider,
            mode=permission.mode,
            content=final_response.content,
            reason=permission.reason,
            reset_provider=(
                permission.reset_provider
            ),
            reset_minutes=(
                permission.reset_minutes
            ),
               metadata={
    "model": final_response.model,
    "tool_calls": len(
        final_response.tool_calls
    ),
    "billing_enabled": (
        self.billing_policy.paid_enabled
    ),
    "billing_mode": (
        self.billing_policy.mode.value
    ),
    "paid_provider": (
        self.paid_provider
    ),
},
        )

        return gateway_response, final_response

    # ==========================================================
    # USER-FACING BLOCK MESSAGE
    # ==========================================================

    @staticmethod
    def blocked_message(
        response: AIGatewayResponse,
    ) -> str:
        """
        Build the user-facing message when AI usage is blocked.
        """

        if response.reset_minutes is not None:

            if response.reset_minutes <= 0:

                reset_text = (
                    "Free AI capacity should be "
                    "available again now."
                )

            else:

                reset_text = (
                    "The nearest free AI capacity "
                    "is expected in approximately "
                    f"{response.reset_minutes} minutes."
                )

        else:

            reset_text = (
                "The next free-provider reset time "
                "is currently unknown."
            )

        return (
            "AI is temporarily unavailable because "
            "all configured free AI providers have "
            "reached their limits. "
            "Paid AI usage has not been authorized "
            "by the administrator. "
            f"{reset_text}"
        )