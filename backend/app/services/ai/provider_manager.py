from __future__ import annotations

from dataclasses import dataclass

from app.services.ai.billing_policy import BillingPolicy
from app.services.ai.quota_manager import QuotaManager


@dataclass
class ProviderDecision:
    """
    Result of the provider-selection decision.
    """

    provider: str | None

    mode: str

    allowed: bool

    reason: str

    reset_provider: str | None = None

    reset_minutes: int | None = None


class ProviderManager:
    """
    Decides which AI provider Trav Planner may use.

    IMPORTANT:

        FREE always wins.

        PAID is considered only after all configured
        free providers are unavailable.

        PAID requires explicit Admin authorization.
    """

    def __init__(
        self,
        *,
        quota_manager: QuotaManager,
        billing_policy: BillingPolicy,
        free_providers: list[str],
        paid_provider: str | None = None,
    ) -> None:

        self.quota_manager = quota_manager

        self.billing_policy = billing_policy

        self.free_providers = free_providers

        self.paid_provider = paid_provider

    def choose(self) -> ProviderDecision:
        """
        Choose the provider that is allowed to handle
        the current request.
        """

        # ======================================================
        # 1. FREE PROVIDERS FIRST
        # ======================================================

        available_free = (
            self.quota_manager.available_free(
                self.free_providers
            )
        )

        if available_free:

            selected = available_free[0]

            return ProviderDecision(
                provider=selected.provider,
                mode="free",
                allowed=True,
                reason=(
                    "Free AI provider is available."
                ),
            )

        # ======================================================
        # 2. ALL FREE PROVIDERS EXHAUSTED
        # ======================================================

        nearest_reset = (
            self.quota_manager.nearest_reset(
                self.free_providers
            )
        )

        reset_provider = None
        reset_minutes = None

        if nearest_reset is not None:

            reset_provider = (
                nearest_reset.provider
            )

            reset_minutes = (
                nearest_reset.minutes_until_reset()
            )

        # ======================================================
        # 3. ADMIN PAID BILLING GATE
        # ======================================================

        if not self.billing_policy.can_use_paid():

            return ProviderDecision(
                provider=None,
                mode="blocked",
                allowed=False,
                reason=(
                    "All free AI providers are exhausted "
                    "and paid AI has not been authorized "
                    "by Admin."
                ),
                reset_provider=reset_provider,
                reset_minutes=reset_minutes,
            )

        # ======================================================
        # 4. PAID PROVIDER CONFIGURATION
        # ======================================================

        if not self.paid_provider:

            return ProviderDecision(
                provider=None,
                mode="blocked",
                allowed=False,
                reason=(
                    "Paid AI is authorized, but no "
                    "paid provider has been configured."
                ),
                reset_provider=reset_provider,
                reset_minutes=reset_minutes,
            )

        # ======================================================
        # 5. PAID FALLBACK
        # ======================================================

        return ProviderDecision(
            provider=self.paid_provider,
            mode="paid",
            allowed=True,
            reason=(
                "All free AI providers are exhausted "
                "and Admin has authorized paid AI."
            ),
            reset_provider=reset_provider,
            reset_minutes=reset_minutes,
        )