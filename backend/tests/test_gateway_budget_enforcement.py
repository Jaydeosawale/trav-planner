from __future__ import annotations

import asyncio

from app.database.session import SessionLocal
from app.integrations.llm.base import LLMResponse, LLMUsage
from app.integrations.llm.gateway import AIGateway
from app.modules.admin.repository import AIBillingRepository
from app.services.ai.billing_policy import (
    BillingMode,
    BillingPolicy,
)
from app.services.ai.quota_manager import (
    ProviderQuota,
    QuotaManager,
)


# ==============================================================
# HELPERS
# ==============================================================


def print_case(title: str) -> None:
    print()
    print("=" * 60)
    print(title)
    print("=" * 60)


class FakeLLMProvider:
    """
    Fake provider.

    No real Groq/Gemini/Ollama request is made.

    Usage:
        Input  = 1,000,000
        Output =   500,000

    Groq pricing:
        Input  = $0.05
        Output = $0.04
        Total  = $0.09
    """

    def __init__(
        self,
        *,
        provider: str = "groq",
        model: str = "llama-3.1-8b-instant",
    ) -> None:
        self._provider = provider
        self._model = model

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
            content="Fake paid AI response.",
            provider=self._provider,
            model=self._model,
            usage=LLMUsage(
                input_tokens=1_000_000,
                output_tokens=500_000,
                total_tokens=1_500_000,
            ),
            raw_response=None,
        )


# ==============================================================
# QUOTA SETUP
# ==============================================================


def exhaust_free_providers(
    quota_manager: QuotaManager,
) -> None:
    """
    Make all configured free providers unavailable.

    This forces the Gateway to reach the paid-billing decision.
    """

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


# ==============================================================
# DATABASE HELPERS
# ==============================================================


async def get_settings():
    async with SessionLocal() as db:
        return await AIBillingRepository.get_settings(db)


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


# ==============================================================
# MAIN TEST
# ==============================================================


async def main() -> None:

    print("=" * 60)
    print("AI GATEWAY BUDGET ENFORCEMENT TEST")
    print("=" * 60)

    # ==========================================================
    # SAVE ORIGINAL DATABASE STATE
    # ==========================================================

    async with SessionLocal() as db:

        settings = (
            await AIBillingRepository.get_settings(db)
        )

        if settings is None:

            settings = (
                await AIBillingRepository.create_settings(
                    db,
                    paid_enabled=False,
                    billing_mode=(
                        BillingMode.FREE_ONLY.value
                    ),
                    paid_provider="groq",
                    daily_budget=10.0,
                    monthly_budget=100.0,
                    daily_spent=0.0,
                    monthly_spent=0.0,
                    updated_by=None,
                )
            )

            await db.commit()

        original_state = {
            "paid_enabled": settings.paid_enabled,
            "billing_mode": settings.billing_mode,
            "paid_provider": settings.paid_provider,
            "daily_budget": settings.daily_budget,
            "monthly_budget": settings.monthly_budget,
            "daily_spent": settings.daily_spent,
            "monthly_spent": settings.monthly_spent,
            "updated_by": settings.updated_by,
        }

    # ==========================================================
    # QUOTA MANAGER
    # ==========================================================

    quota_manager = QuotaManager()

    exhaust_free_providers(
        quota_manager
    )

    # ==========================================================
    # BILLING POLICY
    # ==========================================================

    billing_policy = BillingPolicy(
        paid_enabled=True,
        mode=BillingMode.SOFT,
        daily_budget=5.0,
        monthly_budget=20.0,
        daily_spent=0.0,
        monthly_spent=0.0,
    )

    # ==========================================================
    # GATEWAY
    # ==========================================================

    gateway = AIGateway(
        quota_manager=quota_manager,
        billing_policy=billing_policy,
        free_providers=[
            "groq",
            "gemini",
        ],
        paid_provider="groq",
    )

    # ==========================================================
    # FAKE PROVIDER
    # ==========================================================

    fake_provider = FakeLLMProvider(
        provider="groq",
        model="llama-3.1-8b-instant",
    )

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

        # ======================================================
        # CASE 1 — BELOW DAILY BUDGET
        # ======================================================

        print_case(
            "CASE 1 — BELOW DAILY BUDGET"
        )

        await update_billing(
            paid_enabled=True,
            billing_mode=BillingMode.SOFT.value,
            daily_budget=5.0,
            monthly_budget=20.0,
            daily_spent=0.0,
            monthly_spent=0.0,
        )

        response = await gateway.generate(
            "Create a short Goa itinerary.",
        )

        print("Allowed       :", response.allowed)
        print("Provider      :", response.provider)
        print("Mode          :", response.mode)
        print("Expected cost : $0.09")

        assert response.allowed is True
        assert response.provider == "groq"
        assert response.mode == "paid"

        print("PASSED")

        # ======================================================
        # CASE 2 — VERIFY SPENDING AFTER REQUEST
        # ======================================================

        print_case(
            "CASE 2 — VERIFY SPENDING AFTER REQUEST"
        )

        async with SessionLocal() as db:

            settings = (
                await AIBillingRepository.get_settings(
                    db
                )
            )

            assert settings is not None

            print(
                "Daily spent  :",
                settings.daily_spent,
            )

            print(
                "Monthly spent:",
                settings.monthly_spent,
            )

            assert abs(
                settings.daily_spent - 0.09
            ) < 0.000001

            assert abs(
                settings.monthly_spent - 0.09
            ) < 0.000001

        print("PASSED")

        # ======================================================
        # CASE 3 — DAILY BUDGET REACHED
        # ======================================================

        print_case(
            "CASE 3 — DAILY BUDGET REACHED"
        )

        await update_billing(
            paid_enabled=True,
            billing_mode=BillingMode.SOFT.value,
            daily_budget=5.0,
            monthly_budget=20.0,
            daily_spent=5.0,
            monthly_spent=5.0,
        )

        response = await gateway.generate(
            "Create another paid travel plan.",
        )

        print("Allowed :", response.allowed)
        print("Mode    :", response.mode)
        print("Reason  :", response.reason)

        assert response.allowed is False
        assert response.mode == "blocked"

        assert (
            "billing policy"
            in response.reason.lower()
            or "paid"
            in response.reason.lower()
        )

        print(
            "Paid request correctly blocked "
            "at daily budget."
        )

        print("PASSED")

        # ======================================================
        # CASE 4 — MONTHLY BUDGET REACHED
        # ======================================================

        print_case(
            "CASE 4 — MONTHLY BUDGET REACHED"
        )

        await update_billing(
            paid_enabled=True,
            billing_mode=BillingMode.SOFT.value,
            daily_budget=20.0,
            monthly_budget=5.0,
            daily_spent=0.0,
            monthly_spent=5.0,
        )

        response = await gateway.generate(
            "Create a premium Rajasthan itinerary.",
        )

        print("Allowed :", response.allowed)
        print("Mode    :", response.mode)
        print("Reason  :", response.reason)

        assert response.allowed is False
        assert response.mode == "blocked"

        assert (
            "billing policy"
            in response.reason.lower()
            or "paid"
            in response.reason.lower()
        )

        print(
            "Paid request correctly blocked "
            "at monthly budget."
        )

        print("PASSED")

        # ======================================================
        # CASE 5 — DAILY BUDGET BELOW LIMIT
        # ======================================================

        print_case(
            "CASE 5 — DAILY BUDGET BELOW LIMIT"
        )

        await update_billing(
            paid_enabled=True,
            billing_mode=BillingMode.SOFT.value,
            daily_budget=5.0,
            monthly_budget=20.0,
            daily_spent=4.0,
            monthly_spent=4.0,
        )

        response = await gateway.generate(
            "Create a premium Kerala itinerary.",
        )

        print("Allowed       :", response.allowed)
        print("Provider      :", response.provider)
        print("Mode          :", response.mode)
        print("Current daily : $4.00")
        print("Request cost  : $0.09")
        print("Daily budget  : $5.00")

        assert response.allowed is True
        assert response.provider == "groq"
        assert response.mode == "paid"

        print("PASSED")

        # ======================================================
        # CASE 6 — SPENDING CROSSES DAILY BUDGET
        # ======================================================

        print_case(
            "CASE 6 — SPENDING CROSSES DAILY BUDGET"
        )

        async with SessionLocal() as db:

            settings = (
                await AIBillingRepository.get_settings(
                    db
                )
            )

            assert settings is not None

            print(
                "Daily spent after request :",
                settings.daily_spent,
            )

            print(
                "Daily budget              :",
                settings.daily_budget,
            )

            # 4.00 + 0.09 = 4.09
            assert abs(
                settings.daily_spent - 4.09
            ) < 0.000001

            assert (
                settings.daily_spent
                < settings.daily_budget
            )

        print(
            "Spending recorded correctly."
        )

        print("PASSED")

        # ======================================================
        # CASE 7 — NEXT REQUEST BLOCKED
        # ======================================================

        print_case(
            "CASE 7 — NEXT REQUEST STILL ALLOWED BELOW LIMIT"
        )

        response = await gateway.generate(
            "Create a premium Mumbai itinerary.",
        )

        print("Allowed :", response.allowed)
        print("Provider:", response.provider)
        print("Mode    :", response.mode)

        assert response.allowed is True
        assert response.provider == "groq"
        assert response.mode == "paid"

        print(
            "Paid request remains allowed "
            "while budget is still below limit."
        )

        print("PASSED")

        # ======================================================
        # CASE 8 — EXACT DAILY BUDGET
        # ======================================================

        print_case(
            "CASE 8 — EXACT DAILY BUDGET"
        )

        await update_billing(
            paid_enabled=True,
            billing_mode=BillingMode.SOFT.value,
            daily_budget=5.0,
            monthly_budget=20.0,
            daily_spent=5.0,
            monthly_spent=5.0,
        )

        response = await gateway.generate(
            "Create another itinerary.",
        )

        print("Allowed :", response.allowed)
        print("Mode    :", response.mode)
        print("Reason  :", response.reason)

        assert response.allowed is False
        assert response.mode == "blocked"

        print(
            "Exact daily budget correctly blocks "
            "the next paid request."
        )

        print("PASSED")

        # ======================================================
        # CASE 9 — PAID DISABLED OVERRIDES BUDGET
        # ======================================================

        print_case(
            "CASE 9 — PAID DISABLED OVERRIDES BUDGET"
        )

        await update_billing(
            paid_enabled=False,
            billing_mode=BillingMode.SOFT.value,
            daily_budget=100.0,
            monthly_budget=100.0,
            daily_spent=0.0,
            monthly_spent=0.0,
        )

        response = await gateway.generate(
            "Create a luxury travel itinerary.",
        )

        print("Allowed :", response.allowed)
        print("Mode    :", response.mode)
        print("Reason  :", response.reason)

        assert response.allowed is False
        assert response.mode == "blocked"

        print(
            "Admin paid_enabled=False correctly "
            "overrides available budget."
        )

        print("PASSED")

        # ======================================================
        # CASE 10 — FREE_ONLY OVERRIDES BUDGET
        # ======================================================

        print_case(
            "CASE 10 — FREE_ONLY OVERRIDES BUDGET"
        )

        await update_billing(
            paid_enabled=True,
            billing_mode=BillingMode.FREE_ONLY.value,
            daily_budget=100.0,
            monthly_budget=100.0,
            daily_spent=0.0,
            monthly_spent=0.0,
        )

        response = await gateway.generate(
            "Create a premium travel itinerary.",
        )

        print("Allowed :", response.allowed)
        print("Mode    :", response.mode)
        print("Reason  :", response.reason)

        assert response.allowed is False
        assert response.mode == "blocked"

        print(
            "FREE_ONLY correctly prevents paid fallback."
        )

        print("PASSED")

        # ======================================================
        # FINAL
        # ======================================================

        print()
        print("=" * 60)
        print(
            "AI GATEWAY BUDGET ENFORCEMENT TEST: PASSED"
        )
        print("=" * 60)

    finally:

        # ======================================================
        # RESTORE METHOD
        # ======================================================

        gateway._create_provider = (
            original_create_provider
        )

        # ======================================================
        # RESTORE DATABASE
        # ======================================================

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
                    original_state["paid_enabled"]
                )

                settings.billing_mode = (
                    original_state["billing_mode"]
                )

                settings.paid_provider = (
                    original_state["paid_provider"]
                )

                settings.daily_budget = (
                    original_state["daily_budget"]
                )

                settings.monthly_budget = (
                    original_state["monthly_budget"]
                )

                settings.daily_spent = (
                    original_state["daily_spent"]
                )

                settings.monthly_spent = (
                    original_state["monthly_spent"]
                )

                settings.updated_by = (
                    original_state["updated_by"]
                )

                await db.commit()

        print("Original billing state restored.")
        print("PASSED")


if __name__ == "__main__":
    asyncio.run(main())