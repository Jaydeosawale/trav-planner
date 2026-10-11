from __future__ import annotations

import asyncio

from app.database.session import SessionLocal
from app.integrations.llm.base import (
    LLMResponse,
    LLMToolCall,
    LLMUsage,
)
from app.integrations.llm.gateway import (
    AIGateway,
)
from app.modules.admin.repository import (
    AIBillingRepository,
)
from app.services.ai.billing_policy import (
    BillingMode,
    BillingPolicy,
)
from app.services.ai.quota_manager import (
    ProviderQuota,
    QuotaManager,
)


# ============================================================
# HELPERS
# ============================================================


def print_case(title: str) -> None:
    print()
    print("=" * 60)
    print(title)
    print("=" * 60)


# ============================================================
# FAKE TOOL-CALLING PROVIDER
# ============================================================


class FakeToolCallingProvider:
    """
    Fake Groq provider.

    No real Groq/Gemini API call is made.

    First call:
        LLM asks to execute a tool.

    Continuation:
        LLM receives the tool result and returns final text.

    Each response uses:
        Input  = 1,000,000
        Output =   500,000

    Groq pricing:
        Input  = $0.05
        Output = $0.04

        Total = $0.09 per response
    """

    def __init__(
        self,
        *,
        provider: str = "groq",
        model: str = "llama-3.1-8b-instant",
    ) -> None:

        self._provider = provider
        self._model = model

        self.generate_with_tools_called = False
        self.continue_called = False

        self.last_prompt: str | None = None
        self.last_tool_results: list[dict] | None = None

    @property
    def provider_name(self) -> str:
        return self._provider

    @property
    def model_name(self) -> str:
        return self._model

    async def generate(
        self,
        prompt: str,
        *,
        system_prompt: str | None = None,
        temperature: float = 0.2,
        max_output_tokens: int = 4096,
        **kwargs,
    ) -> LLMResponse:

        return LLMResponse(
            content="Fake normal response.",
            provider=self._provider,
            model=self._model,
            usage=LLMUsage(
                input_tokens=1_000_000,
                output_tokens=500_000,
                total_tokens=1_500_000,
            ),
        )

    async def generate_with_tools(
        self,
        prompt: str,
        *,
        tools: list[dict],
        system_prompt: str | None = None,
        temperature: float = 0.2,
        max_output_tokens: int = 4096,
        **kwargs,
    ) -> LLMResponse:

        self.generate_with_tools_called = True
        self.last_prompt = prompt

        return LLMResponse(
            content="I need weather information before answering.",
            provider=self._provider,
            model=self._model,
            tool_calls=[
                LLMToolCall(
                    id="call_weather_001",
                    name="get_weather",
                    arguments={
                        "city": "Goa",
                    },
                )
            ],
            usage=LLMUsage(
                input_tokens=1_000_000,
                output_tokens=500_000,
                total_tokens=1_500_000,
            ),
        )

    async def continue_with_tool_results(
        self,
        *,
        response: LLMResponse,
        tool_results: list[dict],
        tools: list[dict],
        system_prompt: str | None = None,
        temperature: float = 0.2,
        max_output_tokens: int = 4096,
        **kwargs,
    ) -> LLMResponse:

        self.continue_called = True
        self.last_tool_results = tool_results

        return LLMResponse(
            content=(
                "The weather in Goa is sunny. "
                "It is a good time to travel."
            ),
            provider=self._provider,
            model=self._model,
            usage=LLMUsage(
                input_tokens=1_000_000,
                output_tokens=500_000,
                total_tokens=1_500_000,
            ),
        )


# ============================================================
# DATABASE HELPERS
# ============================================================


async def read_billing_state() -> dict:
    async with SessionLocal() as db:

        settings = (
            await AIBillingRepository.get_settings(db)
        )

        assert settings is not None

        return {
            "paid_enabled": settings.paid_enabled,
            "billing_mode": settings.billing_mode,
            "paid_provider": settings.paid_provider,
            "daily_budget": settings.daily_budget,
            "monthly_budget": settings.monthly_budget,
            "daily_spent": settings.daily_spent,
            "monthly_spent": settings.monthly_spent,
            "updated_by": settings.updated_by,
        }


async def update_billing(
    *,
    paid_enabled: bool,
    billing_mode: str,
    daily_budget: float,
    monthly_budget: float,
    daily_spent: float,
    monthly_spent: float,
) -> None:

    async with SessionLocal() as db:

        settings = (
            await AIBillingRepository.get_settings(db)
        )

        assert settings is not None

        settings.paid_enabled = paid_enabled
        settings.billing_mode = billing_mode
        settings.paid_provider = "groq"
        settings.daily_budget = daily_budget
        settings.monthly_budget = monthly_budget
        settings.daily_spent = daily_spent
        settings.monthly_spent = monthly_spent

        await db.commit()


# ============================================================
# QUOTA SETUP
# ============================================================


def exhaust_free_providers(
    quota_manager: QuotaManager,
) -> None:

    quota_manager.update(
        ProviderQuota(
            provider="groq",
            model="llama-3.1-8b-instant",
            free_available=False,
            remaining_requests=0,
            remaining_tokens=0,
        )
    )

    quota_manager.update(
        ProviderQuota(
            provider="gemini",
            model="gemini-3.5-flash",
            free_available=False,
            remaining_requests=0,
            remaining_tokens=0,
        )
    )


# ============================================================
# MAIN TEST
# ============================================================


async def main() -> None:

    print("=" * 60)
    print("AI GATEWAY TOOL CALLING TEST")
    print("=" * 60)

    # ========================================================
    # SAVE ORIGINAL BILLING STATE
    # ========================================================

    original_state = await read_billing_state()

    # ========================================================
    # ENABLE PAID BILLING FOR TEST
    # ========================================================

    await update_billing(
        paid_enabled=True,
        billing_mode=BillingMode.SOFT.value,
        daily_budget=5.0,
        monthly_budget=20.0,
        daily_spent=0.0,
        monthly_spent=0.0,
    )

    # ========================================================
    # QUOTA
    # ========================================================

    quota_manager = QuotaManager()

    exhaust_free_providers(
        quota_manager
    )

    # ========================================================
    # BILLING POLICY
    # ========================================================

    billing_policy = BillingPolicy(
        paid_enabled=True,
        mode=BillingMode.SOFT,
        daily_budget=5.0,
        monthly_budget=20.0,
        daily_spent=0.0,
        monthly_spent=0.0,
    )

    # ========================================================
    # GATEWAY
    # ========================================================

    gateway = AIGateway(
        quota_manager=quota_manager,
        billing_policy=billing_policy,
        free_providers=[
            "groq",
            "gemini",
        ],
        paid_provider="groq",
    )

    # ========================================================
    # FAKE PROVIDER
    # ========================================================

    fake_provider = FakeToolCallingProvider()

    original_create_provider = (
        gateway._create_provider
    )

    def fake_create_provider(
        provider_name: str,
    ):

        if provider_name == "groq":
            return fake_provider

        raise ValueError(
            f"Unexpected provider: {provider_name}"
        )

    gateway._create_provider = (
        fake_create_provider
    )

    try:

        # ====================================================
        # TOOL DEFINITION
        # ====================================================

        tools = [
            {
                "name": "get_weather",
                "description": (
                    "Get current weather for a city."
                ),
                "parameters": {
                    "type": "object",
                    "properties": {
                        "city": {
                            "type": "string",
                            "description": (
                                "City name."
                            ),
                        }
                    },
                    "required": ["city"],
                },
            }
        ]

        # ====================================================
        # CASE 1
        # ====================================================

        print_case(
            "CASE 1 — GENERATE WITH TOOLS"
        )

        gateway_response, llm_response = (
            await gateway.generate_with_tools(
                "What is the weather in Goa?",
                tools=tools,
            )
        )

        assert gateway_response.allowed is True
        assert gateway_response.provider == "groq"
        assert gateway_response.mode == "paid"

        assert llm_response is not None

        print(
            "Allowed       :",
            gateway_response.allowed,
        )

        print(
            "Provider      :",
            gateway_response.provider,
        )

        print(
            "Mode          :",
            gateway_response.mode,
        )

        print(
            "Tool calls    :",
            len(llm_response.tool_calls),
        )

        assert len(
            llm_response.tool_calls
        ) == 1

        tool_call = (
            llm_response.tool_calls[0]
        )

        print(
            "Tool ID       :",
            tool_call.id,
        )

        print(
            "Tool name     :",
            tool_call.name,
        )

        print(
            "Tool arguments:",
            tool_call.arguments,
        )

        assert (
            tool_call.name
            == "get_weather"
        )

        assert (
            tool_call.arguments["city"]
            == "Goa"
        )

        assert (
            fake_provider.generate_with_tools_called
            is True
        )

        print("PASSED")

        # ====================================================
        # CASE 2
        # ====================================================

        print_case(
            "CASE 2 — VERIFY FIRST RESPONSE COST"
        )

        state = await read_billing_state()

        print(
            "Daily spent  :",
            state["daily_spent"],
        )

        print(
            "Monthly spent:",
            state["monthly_spent"],
        )

        print(
            "Expected cost: $0.09"
        )

        assert abs(
            state["daily_spent"] - 0.09
        ) < 0.000001

        assert abs(
            state["monthly_spent"] - 0.09
        ) < 0.000001

        print("PASSED")

        # ====================================================
        # CASE 3
        # ====================================================

        print_case(
            "CASE 3 — EXECUTE TOOL"
        )

        tool_results = [
            {
                "tool_call_id": tool_call.id,
                "name": tool_call.name,
                "result": {
                    "city": "Goa",
                    "temperature_c": 29,
                    "condition": "Sunny",
                },
            }
        ]

        print(
            "Tool executed:",
            tool_call.name,
        )

        print(
            "Tool result  :",
            tool_results[0]["result"],
        )

        assert (
            tool_results[0]["tool_call_id"]
            == tool_call.id
        )

        print("PASSED")

        # ====================================================
        # CASE 4
        # ====================================================

        print_case(
            "CASE 4 — CONTINUE WITH TOOL RESULTS"
        )

        final_gateway_response, final_response = (
            await gateway.continue_with_tool_results(
                response=llm_response,
                tool_results=tool_results,
                tools=tools,
            )
        )

        assert (
            final_gateway_response.allowed
            is True
        )

        assert (
            final_gateway_response.provider
            == "groq"
        )

        assert (
            final_gateway_response.mode
            == "paid"
        )

        assert final_response is not None

        print(
            "Allowed       :",
            final_gateway_response.allowed,
        )

        print(
            "Provider      :",
            final_gateway_response.provider,
        )

        print(
            "Mode          :",
            final_gateway_response.mode,
        )

        print(
            "Final content :",
            final_response.content,
        )

        assert (
            "weather"
            in final_response.content.lower()
        )

        assert (
            fake_provider.continue_called
            is True
        )

        assert (
            fake_provider.last_tool_results
            == tool_results
        )

        print("PASSED")

        # ====================================================
        # CASE 5
        # ====================================================

        print_case(
            "CASE 5 — VERIFY CONTINUATION COST"
        )

        state = await read_billing_state()

        print(
            "Daily spent  :",
            state["daily_spent"],
        )

        print(
            "Monthly spent:",
            state["monthly_spent"],
        )

        print(
            "Expected total: $0.18"
        )

        # First response  = $0.09
        # Continuation    = $0.09
        # Total            = $0.18

        assert abs(
            state["daily_spent"] - 0.18
        ) < 0.000001

        assert abs(
            state["monthly_spent"] - 0.18
        ) < 0.000001

        print(
            "Both tool-call stages were "
            "persisted correctly."
        )

        print("PASSED")

        # ====================================================
        # CASE 6
        # ====================================================

        print_case(
            "CASE 6 — SAME PROVIDER CONTINUATION"
        )

        print(
            "Original provider :",
            llm_response.provider,
        )

        print(
            "Final provider    :",
            final_response.provider,
        )

        assert (
            llm_response.provider
            == final_response.provider
        )

        assert (
            llm_response.provider
            == "groq"
        )

        print(
            "Continuation stayed "
            "on the original provider."
        )

        print("PASSED")

        # ====================================================
        # CASE 7
        # ====================================================

        print_case(
            "CASE 7 — GATEWAY METADATA"
        )

        print(
            "Model:",
            final_gateway_response.metadata[
                "model"
            ],
        )

        print(
            "Tool calls:",
            final_gateway_response.metadata[
                "tool_calls"
            ],
        )

        print(
            "Billing enabled:",
            final_gateway_response.metadata[
                "billing_enabled"
            ],
        )

        print(
            "Billing mode:",
            final_gateway_response.metadata[
                "billing_mode"
            ],
        )

        print(
            "Paid provider:",
            final_gateway_response.metadata[
                "paid_provider"
            ],
        )

        assert (
            final_gateway_response.metadata[
                "model"
            ]
            == "llama-3.1-8b-instant"
        )

        assert (
            final_gateway_response.metadata[
                "tool_calls"
            ]
            == 0
        )

        assert (
            final_gateway_response.metadata[
                "billing_enabled"
            ]
            is True
        )

        assert (
            final_gateway_response.metadata[
                "billing_mode"
            ]
            == "soft"
        )

        assert (
            final_gateway_response.metadata[
                "paid_provider"
            ]
            == "groq"
        )

        print("PASSED")

        # ====================================================
        # FINAL
        # ====================================================

        print()
        print("=" * 60)
        print(
            "AI GATEWAY TOOL CALLING TEST: PASSED"
        )
        print("=" * 60)

    finally:

        # ====================================================
        # RESTORE GATEWAY METHOD
        # ====================================================

        gateway._create_provider = (
            original_create_provider
        )

        # ====================================================
        # RESTORE DATABASE
        # ====================================================

        print()
        print("=" * 60)
        print(
            "CLEANUP — RESTORE ORIGINAL BILLING STATE"
        )
        print("=" * 60)

        async with SessionLocal() as db:

            settings = (
                await AIBillingRepository.get_settings(
                    db
                )
            )

            if settings is not None:

                settings.paid_enabled = (
                    original_state[
                        "paid_enabled"
                    ]
                )

                settings.billing_mode = (
                    original_state[
                        "billing_mode"
                    ]
                )

                settings.paid_provider = (
                    original_state[
                        "paid_provider"
                    ]
                )

                settings.daily_budget = (
                    original_state[
                        "daily_budget"
                    ]
                )

                settings.monthly_budget = (
                    original_state[
                        "monthly_budget"
                    ]
                )

                settings.daily_spent = (
                    original_state[
                        "daily_spent"
                    ]
                )

                settings.monthly_spent = (
                    original_state[
                        "monthly_spent"
                    ]
                )

                settings.updated_by = (
                    original_state[
                        "updated_by"
                    ]
                )

                await db.commit()

        print(
            "Original billing state restored."
        )
        print("PASSED")


if __name__ == "__main__":
    asyncio.run(main())