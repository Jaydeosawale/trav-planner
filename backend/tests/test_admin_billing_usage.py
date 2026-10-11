from __future__ import annotations

import asyncio

from app.database.session import SessionLocal
from app.services.ai.admin_billing_service import (
    AdminBillingService,
)
from app.services.ai.billing_policy import (
    BillingMode,
    BillingPolicy,
)


async def main() -> None:

    print("=" * 60)
    print("ADMIN BILLING USAGE COST TEST")
    print("=" * 60)

    # ==========================================================
    # CASE 1 — DISABLED BILLING
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 1 — PAID BILLING DISABLED")
    print("=" * 60)

    policy = BillingPolicy(
        paid_enabled=False,
        mode=BillingMode.FREE_ONLY,
    )

    service = AdminBillingService(
        billing_policy=policy,
        paid_provider="groq",
    )

    try:
        async with SessionLocal() as db:
            await service.load_from_database(db)

            # Database currently has paid disabled, so this
            # should be rejected.
            await service.record_usage_cost(
                db,
                amount=0.50,
                provider="groq",
                model="llama-3.1-8b-instant",
            )

        raise AssertionError(
            "Disabled paid billing was not rejected."
        )

    except PermissionError as exc:
        print("Rejected correctly:", exc)

    print("PASSED")

    # ==========================================================
    # CASE 2 — ZERO COST
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 2 — ZERO COST")
    print("=" * 60)

    policy = BillingPolicy(
        paid_enabled=True,
        mode=BillingMode.HARD,
    )

    service = AdminBillingService(
        billing_policy=policy,
        paid_provider="groq",
    )

    async with SessionLocal() as db:

        await service.load_from_database(db)

        before_daily = service.get_state().daily_spent
        before_monthly = service.get_state().monthly_spent

        # Don't use the database state for this case if it is
        # FREE_ONLY; this case verifies the method itself.
        service._policy.paid_enabled = True
        service._policy.mode = BillingMode.HARD

        state = await service.record_usage_cost(
            db,
            amount=0.0,
            provider="groq",
            model="llama-3.1-8b-instant",
        )

        assert state.daily_spent == before_daily
        assert state.monthly_spent == before_monthly

    print("Daily unchanged  :", state.daily_spent)
    print("Monthly unchanged:", state.monthly_spent)
    print("PASSED")

    # ==========================================================
    # CASE 3 — REAL COST RECORDING
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 3 — RECORD $0.50")
    print("=" * 60)

    policy = BillingPolicy(
        paid_enabled=True,
        mode=BillingMode.HARD,
    )

    service = AdminBillingService(
        billing_policy=policy,
        paid_provider="groq",
    )

    async with SessionLocal() as db:

        await service.load_from_database(db)

        # Force paid mode for this isolated test.
        service._policy.paid_enabled = True
        service._policy.mode = BillingMode.HARD

        before_daily = service.get_state().daily_spent
        before_monthly = service.get_state().monthly_spent

        state = await service.record_usage_cost(
            db,
            amount=0.50,
            provider="groq",
            model="llama-3.1-8b-instant",
        )

        assert state.daily_spent == (
            before_daily + 0.50
        )

        assert state.monthly_spent == (
            before_monthly + 0.50
        )

        print("Daily spent  :", state.daily_spent)
        print("Monthly spent:", state.monthly_spent)

    print("PASSED")

    # ==========================================================
    # CASE 4 — WRONG PROVIDER
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 4 — WRONG PROVIDER")
    print("=" * 60)

    policy = BillingPolicy(
        paid_enabled=True,
        mode=BillingMode.HARD,
    )

    service = AdminBillingService(
        billing_policy=policy,
        paid_provider="groq",
    )

    try:
        async with SessionLocal() as db:

            await service.load_from_database(db)

            service._policy.paid_enabled = True
            service._policy.mode = BillingMode.HARD

            await service.record_usage_cost(
                db,
                amount=0.50,
                provider="gemini",
                model="gemini-3.5-flash",
            )

        raise AssertionError(
            "Wrong provider was not rejected."
        )

    except PermissionError as exc:
        print("Rejected correctly:", exc)

    print("PASSED")

    # ==========================================================
    # CASE 5 — NEGATIVE COST
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 5 — NEGATIVE COST")
    print("=" * 60)

    try:
        async with SessionLocal() as db:

            await service.record_usage_cost(
                db,
                amount=-1.0,
                provider="groq",
                model="llama-3.1-8b-instant",
            )

        raise AssertionError(
            "Negative cost was not rejected."
        )

    except ValueError as exc:
        print("Rejected correctly:", exc)

    print("PASSED")

    # ==========================================================
    # COMPLETE
    # ==========================================================

    print()
    print("=" * 60)
    print("ADMIN BILLING USAGE COST TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())