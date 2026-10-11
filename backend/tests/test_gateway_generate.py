from __future__ import annotations

import asyncio

from app.database.session import SessionLocal
from app.integrations.llm.base import LLMResponse, LLMUsage
from app.integrations.llm.gateway import AIGateway
from app.modules.admin.repository import AIBillingRepository
from app.services.ai.billing_policy import BillingMode, BillingPolicy
from app.services.ai.quota_manager import (
    ProviderQuota,
    QuotaManager,
)


def print_case(title: str) -> None:
    print()
    print("=" * 60)
    print(title)
    print("=" * 60)


class FakeLLMProvider:
    """
    Fake provider used to test AIGateway.generate()
    without making a real LLM API request.
    """

    def __init__(
        self,
        *,
        provider: str,
        model: str,
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
            content=(
                "This is a fake Trav Planner AI response."
            ),
            provider=self._provider,
            model=self._model,
            usage=LLMUsage(
                input_tokens=1_000_000,
                output_tokens=500_000,
                total_tokens=1_500_000,
            ),
            raw_response=None,
        )


async def main() -> None:

    print("=" * 60)
    print("AI GATEWAY GENERATE INTEGRATION TEST")
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

    # ==========================================================
    # BILLING POLICY
    # ==========================================================

    billing_policy = BillingPolicy(
        paid_enabled=False,
        mode=BillingMode.FREE_ONLY,
        daily_budget=10.0,
        monthly_budget=100.0,
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
    # FAKE PROVIDERS
    # ==========================================================

    fake_groq = FakeLLMProvider(
        provider="groq",
        model="llama-3.1-8b-instant",
    )

    fake_gemini = FakeLLMProvider(
        provider="gemini",
        model="gemini-3.5-flash",
    )

    original_create_provider = (
        gateway._create_provider
    )

    def fake_create_provider(
        provider_name: str,
    ):
        if provider_name == "groq":
            return fake_groq

        if provider_name == "gemini":
            return fake_gemini

        raise ValueError(
            f"Unexpected provider in test: "
            f"{provider_name}"
        )

    gateway._create_provider = fake_create_provider

    try:

        # ======================================================
        # CASE 1 — REAL generate() WITH FREE PROVIDER
        # ======================================================

        print_case(
            "CASE 1 — GENERATE THROUGH FREE PROVIDER"
        )

        quota_manager.update(
            ProviderQuota(
                provider="groq",
                model="llama-3.1-8b-instant",
                free_available=True,
                remaining_requests=100,
                remaining_tokens=100000,
            )
        )

        quota_manager.update(
            ProviderQuota(
                provider="gemini",
                model="gemini-3.5-flash",
                free_available=True,
                remaining_requests=100,
                remaining_tokens=100000,
            )
        )

        # Make sure database is free-only.
        async with SessionLocal() as db:

            settings = (
                await AIBillingRepository.get_settings(
                    db
                )
            )

            assert settings is not None

            settings.paid_enabled = False
            settings.billing_mode = (
                BillingMode.FREE_ONLY.value
            )
            settings.daily_spent = 0.0
            settings.monthly_spent = 0.0

            await db.commit()

        response = await gateway.generate(
            "Create a short travel plan for Mumbai.",
        )

        print("Allowed  :", response.allowed)
        print("Provider :", response.provider)
        print("Mode     :", response.mode)
        print("Content  :", response.content)

        assert response.allowed is True
        assert response.provider == "groq"
        assert response.mode == "free"

        assert (
            response.content
            == "This is a fake Trav Planner AI response."
        )

        print("PASSED")

        # ======================================================
        # CASE 2 — VERIFY FREE REQUEST DOES NOT CREATE
        #           PAID SPENDING
        # ======================================================

        print_case(
            "CASE 2 — FREE REQUEST COST"
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

            assert settings.daily_spent == 0.0
            assert settings.monthly_spent == 0.0

        print(
            "Free request produced $0 application billing."
        )

        print("PASSED")

        # ======================================================
        # CASE 3 — EXHAUST FREE PROVIDERS
        # ======================================================

        print_case(
            "CASE 3 — EXHAUST FREE PROVIDERS"
        )

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

        # Confirm paid is still disabled.
        async with SessionLocal() as db:

            settings = (
                await AIBillingRepository.get_settings(
                    db
                )
            )

            assert settings is not None

            settings.paid_enabled = False
            settings.billing_mode = (
                BillingMode.FREE_ONLY.value
            )

            await db.commit()

        response = await gateway.generate(
            "Create a 3-day Goa itinerary.",
        )

        print("Allowed :", response.allowed)
        print("Mode    :", response.mode)
        print("Reason  :", response.reason)
        print("Content :", response.content)

        assert response.allowed is False
        assert response.mode == "blocked"

        print("PASSED")

        # ======================================================
        # CASE 4 — ENABLE PAID BILLING
        # ======================================================

        print_case(
            "CASE 4 — ENABLE ADMIN PAID BILLING"
        )

        async with SessionLocal() as db:

            settings = (
                await AIBillingRepository.get_settings(
                    db
                )
            )

            assert settings is not None

            settings.paid_enabled = True
            settings.billing_mode = (
                BillingMode.SOFT.value
            )
            settings.paid_provider = "groq"
            settings.daily_budget = 5.0
            settings.monthly_budget = 20.0
            settings.daily_spent = 0.0
            settings.monthly_spent = 0.0

            await db.commit()

        print("Paid enabled : True")
        print("Billing mode : soft")
        print("Paid provider: groq")

        print("PASSED")

        # ======================================================
        # CASE 5 — REAL generate() PAID FALLBACK
        # ======================================================

        print_case(
            "CASE 5 — GENERATE THROUGH PAID FALLBACK"
        )

        response = await gateway.generate(
            "Create a premium 5-day Kerala itinerary.",
        )

        print("Allowed  :", response.allowed)
        print("Provider :", response.provider)
        print("Mode     :", response.mode)
        print("Content  :", response.content)

        assert response.allowed is True
        assert response.provider == "groq"
        assert response.mode == "paid"

        assert (
            response.content
            == "This is a fake Trav Planner AI response."
        )

        print("PASSED")

        # ======================================================
        # CASE 6 — VERIFY PAID COST PERSISTED
        # ======================================================

        print_case(
            "CASE 6 — VERIFY PAID COST IN POSTGRESQL"
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

            # Fake response:
            #
            # 1M input  × $0.05 = $0.05
            # 0.5M output × $0.08 = $0.04
            #
            # Total = $0.09

            assert abs(
                settings.daily_spent - 0.09
            ) < 0.000001

            assert abs(
                settings.monthly_spent - 0.09
            ) < 0.000001

        print(
            "Paid generate() → cost → PostgreSQL verified."
        )

        print("PASSED")

        # ======================================================
        # CASE 7 — VERIFY RESPONSE METADATA
        # ======================================================

        print_case(
            "CASE 7 — VERIFY GATEWAY RESPONSE METADATA"
        )

        print(
            "Billing enabled:",
            response.metadata.get(
                "billing_enabled"
            ),
        )

        print(
            "Billing mode   :",
            response.metadata.get(
                "billing_mode"
            ),
        )

        print(
            "Paid provider  :",
            response.metadata.get(
                "paid_provider"
            ),
        )

        assert (
            response.metadata is not None
        )

        assert (
            response.metadata["billing_enabled"]
            is True
        )

        assert (
            response.metadata["billing_mode"]
            == BillingMode.SOFT.value
        )

        assert (
            response.metadata["paid_provider"]
            == "groq"
        )

        print("PASSED")

        # ======================================================
        # COMPLETE
        # ======================================================

        print()
        print("=" * 60)
        print(
            "AI GATEWAY GENERATE INTEGRATION TEST: PASSED"
        )
        print("=" * 60)

    finally:

        # ======================================================
        # RESTORE GATEWAY METHOD
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