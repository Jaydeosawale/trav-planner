from __future__ import annotations

import asyncio

from app.database.session import SessionLocal
from app.integrations.llm.base import LLMResponse, LLMUsage
from app.integrations.llm.gateway import AIGateway
from app.modules.admin.repository import AIBillingRepository


async def main() -> None:

    print("=" * 60)
    print("GATEWAY COST -> POSTGRESQL PERSISTENCE TEST")
    print("=" * 60)

    gateway = AIGateway(
        free_providers=["groq", "gemini"],
        paid_provider="groq",
    )

    original_state = None

    # ==========================================================
    # CASE 1 — READ CURRENT BILLING STATE
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 1 — READ CURRENT BILLING STATE")
    print("=" * 60)

    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        if settings is None:
            raise RuntimeError(
                "AI billing settings do not exist."
            )

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

    print("Paid enabled :", original_state["paid_enabled"])
    print("Billing mode :", original_state["billing_mode"])
    print("Paid provider:", original_state["paid_provider"])
    print("Daily spent  :", original_state["daily_spent"])
    print("Monthly spent:", original_state["monthly_spent"])
    print("PASSED")

    # ==========================================================
    # CASE 2 — TEMPORARILY ENABLE CONTROLLED PAID BILLING
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 2 — ENABLE CONTROLLED PAID BILLING")
    print("=" * 60)

    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        if settings is None:
            raise RuntimeError(
                "AI billing settings do not exist."
            )

        settings.paid_enabled = True
        settings.billing_mode = "soft"
        settings.paid_provider = "groq"

        # Test-only budgets.
        settings.daily_budget = 5.0
        settings.monthly_budget = 20.0

        await db.commit()

    print("Paid enabled : True")
    print("Billing mode : soft")
    print("Paid provider: groq")
    print("Daily budget : $5.00")
    print("Monthly budget: $20.00")
    print("PASSED")

    try:

        # ======================================================
        # CASE 3 — READ TEST STARTING SPENDING
        # ======================================================

        print()
        print("=" * 60)
        print("CASE 3 — READ TEST STARTING SPENDING")
        print("=" * 60)

        async with SessionLocal() as db:

            settings = (
                await AIBillingRepository.get_settings(db)
            )

            if settings is None:
                raise RuntimeError(
                    "AI billing settings do not exist."
                )

            daily_before = settings.daily_spent
            monthly_before = settings.monthly_spent

        print("Daily spent before  :", daily_before)
        print("Monthly spent before:", monthly_before)
        print("PASSED")

        # ======================================================
        # CASE 4 — CREATE FAKE PAID RESPONSE
        # ======================================================

        print()
        print("=" * 60)
        print("CASE 4 — CREATE FAKE PAID RESPONSE")
        print("=" * 60)

        response = LLMResponse(
            content="Controlled billing test response",
            provider="groq",
            model="llama-3.1-8b-instant",
            usage=LLMUsage(
                input_tokens=1_000_000,
                output_tokens=500_000,
                total_tokens=1_500_000,
            ),
        )

        print("Provider     :", response.provider)
        print("Model        :", response.model)
        print("Input tokens :", response.usage.input_tokens)
        print("Output tokens:", response.usage.output_tokens)
        print("Expected cost: $0.09")
        print("PASSED")

        # ======================================================
        # CASE 5 — RECORD THROUGH GATEWAY
        # ======================================================

        print()
        print("=" * 60)
        print("CASE 5 — RECORD COST THROUGH GATEWAY")
        print("=" * 60)

        await gateway._record_response_cost(
            response,
            billing_mode="paid",
        )

        print("Gateway cost recording completed.")
        print("PASSED")

        # ======================================================
        # CASE 6 — VERIFY POSTGRESQL
        # ======================================================

        print()
        print("=" * 60)
        print("CASE 6 — VERIFY POSTGRESQL")
        print("=" * 60)

        async with SessionLocal() as db:

            settings = (
                await AIBillingRepository.get_settings(db)
            )

            if settings is None:
                raise RuntimeError(
                    "AI billing settings do not exist."
                )

            daily_after = settings.daily_spent
            monthly_after = settings.monthly_spent

        daily_difference = (
            daily_after - daily_before
        )

        monthly_difference = (
            monthly_after - monthly_before
        )

        print("Daily spent after  :", daily_after)
        print("Monthly spent after:", monthly_after)
        print("Daily difference   :", daily_difference)
        print("Monthly difference :", monthly_difference)

        assert abs(
            daily_difference - 0.09
        ) < 0.000001

        assert abs(
            monthly_difference - 0.09
        ) < 0.000001

        print("PostgreSQL cost persistence verified.")
        print("PASSED")

    finally:

        # ======================================================
        # CLEANUP — ALWAYS RESTORE ORIGINAL STATE
        # ======================================================

        print()
        print("=" * 60)
        print("CLEANUP — RESTORE ORIGINAL BILLING STATE")
        print("=" * 60)

        if original_state is not None:

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

    # ==========================================================
    # FINAL
    # ==========================================================

    print()
    print("=" * 60)
    print("GATEWAY COST -> POSTGRESQL PERSISTENCE TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())