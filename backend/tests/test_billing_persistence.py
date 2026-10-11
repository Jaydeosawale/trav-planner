from __future__ import annotations

import asyncio

from app.database.session import SessionLocal
from app.services.ai.admin_billing_service import AdminBillingService
from app.services.ai.billing_policy import BillingPolicy
from app.modules.admin.repository import AIBillingRepository


ADMIN_ID = "2babb481-ef01-4ae6-8c11-0df70805ab4c"


async def main() -> None:

    print("=" * 60)
    print("BILLING POSTGRESQL PERSISTENCE TEST")
    print("=" * 60)

    # ==========================================================
    # CASE 1 — LOAD CURRENT BILLING STATE
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 1 — LOAD CURRENT BILLING STATE")
    print("=" * 60)

    service = AdminBillingService(
        billing_policy=BillingPolicy(),
        paid_provider="groq",
    )

    async with SessionLocal() as db:

        state = await service.load_from_database(db)

        print("Paid enabled :", state.paid_enabled)
        print("Billing mode :", state.mode.value)
        print("Daily spent  :", state.daily_spent)
        print("Monthly spent:", state.monthly_spent)

    print("PASSED")

    # ==========================================================
    # CASE 2 — READ DATABASE DIRECTLY
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 2 — READ PERSISTENT VALUES")
    print("=" * 60)

    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        assert settings is not None

        before_daily = settings.daily_spent
        before_monthly = settings.monthly_spent

        print("Daily spent before  :", before_daily)
        print("Monthly spent before:", before_monthly)

    print("PASSED")

    # ==========================================================
    # CASE 3 — RECORD COST
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 3 — RECORD $0.50")
    print("=" * 60)

    service = AdminBillingService(
        billing_policy=BillingPolicy(),
        paid_provider="groq",
    )

    async with SessionLocal() as db:

        await service.load_from_database(db)

        state = await service.record_cost(
            db,
            0.50,
        )

        print("Daily spent  :", state.daily_spent)
        print("Monthly spent:", state.monthly_spent)

    print("PASSED")

    # ==========================================================
    # CASE 4 — RELOAD FROM DATABASE
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 4 — VERIFY PERSISTENCE")
    print("=" * 60)

    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        assert settings is not None

        after_daily = settings.daily_spent
        after_monthly = settings.monthly_spent

        print("Daily spent after  :", after_daily)
        print("Monthly spent after:", after_monthly)

        assert after_daily == before_daily + 0.50
        assert after_monthly == before_monthly + 0.50

    print("Database persistence verified.")
    print("PASSED")

    # ==========================================================
    # CASE 5 — CLEANUP
    # ==========================================================
    #
    # Remove the test amount so this test does not permanently
    # change the development billing budget.
    #

    print()
    print("=" * 60)
    print("CASE 5 — CLEANUP TEST SPENDING")
    print("=" * 60)

    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        assert settings is not None

        settings.daily_spent = before_daily
        settings.monthly_spent = before_monthly

        await db.commit()

    # Verify cleanup.
    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        assert settings is not None

        assert settings.daily_spent == before_daily
        assert settings.monthly_spent == before_monthly

        print("Daily spent restored  :", settings.daily_spent)
        print("Monthly spent restored:", settings.monthly_spent)

    print("PASSED")

    # ==========================================================
    # COMPLETE
    # ==========================================================

    print()
    print("=" * 60)
    print("BILLING POSTGRESQL PERSISTENCE TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())