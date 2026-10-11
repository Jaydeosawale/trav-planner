from __future__ import annotations

import asyncio

from app.database.session import SessionLocal
from app.modules.admin.repository import AIBillingRepository


async def main() -> None:

    print("=" * 60)
    print("BILLING REPOSITORY SPENDING TEST")
    print("=" * 60)

    # ==========================================================
    # CASE 1 — READ CURRENT SETTINGS
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 1 — READ CURRENT SETTINGS")
    print("=" * 60)

    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        assert settings is not None

        original_daily = settings.daily_spent
        original_monthly = settings.monthly_spent

        print("Daily spent before  :", original_daily)
        print("Monthly spent before:", original_monthly)

    print("PASSED")

    # ==========================================================
    # CASE 2 — RECORD SPENDING
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 2 — RECORD $0.50")
    print("=" * 60)

    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        assert settings is not None

        updated = await AIBillingRepository.record_spending(
            db,
            settings,
            amount=0.50,
        )

        assert updated.daily_spent == original_daily + 0.50
        assert updated.monthly_spent == original_monthly + 0.50

        print("Daily spent after  :", updated.daily_spent)
        print("Monthly spent after:", updated.monthly_spent)

        await db.commit()

    print("PASSED")

    # ==========================================================
    # CASE 3 — VERIFY DATABASE PERSISTENCE
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 3 — VERIFY PERSISTENCE")
    print("=" * 60)

    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        assert settings is not None

        assert settings.daily_spent == (
            original_daily + 0.50
        )

        assert settings.monthly_spent == (
            original_monthly + 0.50
        )

        print("Daily persisted  :", settings.daily_spent)
        print("Monthly persisted:", settings.monthly_spent)

    print("PASSED")

    # ==========================================================
    # CASE 4 — NEGATIVE COST
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 4 — NEGATIVE COST")
    print("=" * 60)

    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        assert settings is not None

        try:

            await AIBillingRepository.record_spending(
                db,
                settings,
                amount=-1.0,
            )

            raise AssertionError(
                "Negative spending was not rejected."
            )

        except ValueError as exc:

            print(
                "Negative cost rejected correctly:",
                exc,
            )

    print("PASSED")

    # ==========================================================
    # CASE 5 — CLEANUP
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 5 — CLEANUP")
    print("=" * 60)

    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        assert settings is not None

        settings.daily_spent = original_daily
        settings.monthly_spent = original_monthly

        await db.commit()

    async with SessionLocal() as db:

        settings = await AIBillingRepository.get_settings(db)

        assert settings is not None

        assert settings.daily_spent == original_daily
        assert settings.monthly_spent == original_monthly

        print("Daily restored  :", settings.daily_spent)
        print("Monthly restored:", settings.monthly_spent)

    print("PASSED")

    # ==========================================================
    # COMPLETE
    # ==========================================================

    print()
    print("=" * 60)
    print("BILLING REPOSITORY SPENDING TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())