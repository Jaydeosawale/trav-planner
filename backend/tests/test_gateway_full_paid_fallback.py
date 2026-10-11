from __future__ import annotations

import asyncio

from app.database.session import SessionLocal
from app.integrations.llm.base import LLMResponse, LLMUsage
from app.integrations.llm.gateway import AIGateway
from app.modules.admin.repository import AIBillingRepository
from app.services.ai.admin_billing_service import AdminBillingService
from app.services.ai.billing_policy import BillingMode, BillingPolicy
from app.services.ai.cost_calculator import AICostCalculator
from app.services.ai.pricing import create_pricing_registry
from app.services.ai.quota_manager import (
    ProviderQuota,
    QuotaManager,
)


def print_case(title: str) -> None:
    print()
    print("=" * 60)
    print(title)
    print("=" * 60)


async def main() -> None:

    print("=" * 60)
    print("FULL AI GATEWAY PAID FALLBACK TEST")
    print("=" * 60)

    # ==========================================================
    # INITIALIZE
    # ==========================================================

    quota_manager = QuotaManager()

    billing_policy = BillingPolicy(
        paid_enabled=False,
        mode=BillingMode.FREE_ONLY,
        daily_budget=5.0,
        monthly_budget=20.0,
        daily_spent=0.0,
        monthly_spent=0.0,
    )

    gateway = AIGateway(
        quota_manager=quota_manager,
        billing_policy=billing_policy,
        free_providers=["groq", "gemini"],
        paid_provider="groq",
    )

    # ==========================================================
    # DATABASE SETUP / ORIGINAL STATE
    # ==========================================================

    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        if settings is None:
            settings = (
                await AIBillingRepository.create_settings(
                    db,
                    paid_enabled=False,
                    billing_mode=BillingMode.FREE_ONLY.value,
                    paid_provider="groq",
                    daily_budget=5.0,
                    monthly_budget=20.0,
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
        }

    try:

        # ======================================================
        # CASE 1 — FREE PROVIDER AVAILABLE
        # ======================================================

        print_case("CASE 1 — FREE PROVIDER AVAILABLE")

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

        result = await gateway.check_request()

        print("Allowed  :", result.allowed)
        print("Provider :", result.provider)
        print("Mode     :", result.mode)

        assert result.allowed is True
        assert result.provider == "groq"
        assert result.mode == "free"

        print("PASSED")

        # ======================================================
        # CASE 2 — ALL FREE PROVIDERS EXHAUSTED
        #              PAID DISABLED
        # ======================================================

        print_case(
            "CASE 2 — FREE EXHAUSTED + PAID DISABLED"
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

        async with SessionLocal() as db:

            service = AdminBillingService(
                billing_policy=billing_policy,
                paid_provider="groq",
            )

            await service.disable(
                db,
                admin_id="test-admin",
            )

        result = await gateway.check_request()

        print("Allowed :", result.allowed)
        print("Mode    :", result.mode)
        print("Reason  :", result.reason)

        assert result.allowed is False
        assert result.mode == "blocked"

        print("PASSED")

        # ======================================================
        # CASE 3 — ENABLE CONTROLLED PAID BILLING
        # ======================================================

        print_case(
            "CASE 3 — ENABLE CONTROLLED PAID FALLBACK"
        )

        async with SessionLocal() as db:

            service = AdminBillingService(
                billing_policy=billing_policy,
                paid_provider="groq",
            )

            state = await service.soft_enable(
                db,
                paid_provider="groq",
                daily_budget=5.0,
                monthly_budget=20.0,
                admin_id="test-admin",
            )

            print(
                "Paid enabled :",
                state.paid_enabled,
            )

            print(
                "Billing mode :",
                state.mode.value,
            )

            print(
                "Paid provider:",
                state.paid_provider,
            )

            assert state.paid_enabled is True
            assert state.mode == BillingMode.SOFT
            assert state.paid_provider == "groq"

        print("PASSED")

        # ======================================================
        # CASE 4 — FREE EXHAUSTED → PAID FALLBACK
        # ======================================================

        print_case(
            "CASE 4 — FREE EXHAUSTED → PAID FALLBACK"
        )

        result = await gateway.check_request()

        print("Allowed  :", result.allowed)
        print("Provider :", result.provider)
        print("Mode     :", result.mode)
        print("Reason   :", result.reason)

        assert result.allowed is True
        assert result.provider == "groq"
        assert result.mode == "paid"

        print("PASSED")

        # ======================================================
        # CASE 5 — CREATE FAKE PAID RESPONSE
        # ======================================================

        print_case("CASE 5 — CREATE FAKE PAID RESPONSE")

        fake_response = LLMResponse(
            content="Fake paid AI response.",
            provider="groq",
            model="llama-3.1-8b-instant",
            usage=LLMUsage(
                input_tokens=1_000_000,
                output_tokens=500_000,
                total_tokens=1_500_000,
            ),
            raw_response=None,
        )

        print("Provider     :", fake_response.provider)
        print("Model        :", fake_response.model)
        print(
            "Input tokens :",
            fake_response.usage.input_tokens,
        )
        print(
            "Output tokens:",
            fake_response.usage.output_tokens,
        )

        pricing_registry = create_pricing_registry()

        pricing = pricing_registry.get(
            provider=fake_response.provider,
            model=fake_response.model,
        )

        cost = AICostCalculator.calculate(
            fake_response.usage,
            pricing,
        )

        print(
            "Input cost   :",
            cost.input_cost,
        )

        print(
            "Output cost  :",
            cost.output_cost,
        )

        print(
            "Total cost   :",
            cost.total_cost,
        )

        assert cost.total_cost == 0.09

        print("PASSED")

        # ======================================================
        # CASE 6 — RECORD COST THROUGH GATEWAY
        # ======================================================

        print_case(
            "CASE 6 — RECORD COST THROUGH GATEWAY"
        )

        async with SessionLocal() as db:

            before = (
                await AIBillingRepository.get_settings(
                    db
                )
            )

            assert before is not None

            daily_before = before.daily_spent
            monthly_before = before.monthly_spent

        await gateway._record_response_cost(
          fake_response,
        billing_mode="paid",
)

        async with SessionLocal() as db:

            after = (
                await AIBillingRepository.get_settings(
                    db
                )
            )

            assert after is not None

            daily_after = after.daily_spent
            monthly_after = after.monthly_spent

        print(
            "Daily before  :",
            daily_before,
        )

        print(
            "Daily after   :",
            daily_after,
        )

        print(
            "Monthly before:",
            monthly_before,
        )

        print(
            "Monthly after :",
            monthly_after,
        )

        assert abs(
            daily_after
            - (daily_before + 0.09)
        ) < 0.000001

        assert abs(
            monthly_after
            - (monthly_before + 0.09)
        ) < 0.000001

        print(
            "Gateway → PostgreSQL cost recording verified."
        )

        print("PASSED")

        # ======================================================
        # CASE 7 — BUDGET STILL AVAILABLE
        # ======================================================

        print_case("CASE 7 — BUDGET CHECK")

        async with SessionLocal() as db:

            settings = (
                await AIBillingRepository.get_settings(
                    db
                )
            )

            assert settings is not None

            print(
                "Daily budget :",
                settings.daily_budget,
            )

            print(
                "Daily spent  :",
                settings.daily_spent,
            )

            print(
                "Monthly budget:",
                settings.monthly_budget,
            )

            print(
                "Monthly spent :",
                settings.monthly_spent,
            )

            assert (
                settings.daily_spent
                < settings.daily_budget
            )

            assert (
                settings.monthly_spent
                < settings.monthly_budget
            )

        print("PASSED")

    finally:

        # ======================================================
        # CLEANUP
        # ======================================================

        print()
        print("=" * 60)
        print("CLEANUP — RESTORE ORIGINAL BILLING STATE")
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

                await db.commit()

        print("Original billing state restored.")
        print("PASSED")

    print()
    print("=" * 60)
    print(
        "FULL AI GATEWAY PAID FALLBACK TEST: PASSED"
    )
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())