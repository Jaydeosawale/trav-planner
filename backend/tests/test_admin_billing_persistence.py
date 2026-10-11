import asyncio

from app.database.session import SessionLocal
from app.modules.admin.repository import AIBillingRepository
from app.services.ai.admin_billing_service import (
    AdminBillingService,
)
from app.services.ai.billing_policy import BillingPolicy


async def main():

    print("=" * 60)
    print("AI BILLING POSTGRESQL PERSISTENCE TEST")
    print("=" * 60)

    # ----------------------------------------------------------
    # 1. Create runtime service
    # ----------------------------------------------------------

    policy = BillingPolicy()

    service = AdminBillingService(
        billing_policy=policy,
        paid_provider="groq",
    )

    # ----------------------------------------------------------
    # 2. Load configuration from PostgreSQL
    # ----------------------------------------------------------

    async with SessionLocal() as db:

        state = await service.load_from_database(db)

        print()
        print("STEP 1 — LOAD FROM DATABASE")
        print("Paid enabled :", state.paid_enabled)
        print("Mode         :", state.mode)
        print("Provider     :", state.paid_provider)
        print("Daily budget:", state.daily_budget)
        print("Monthly budget:", state.monthly_budget)

    # ----------------------------------------------------------
    # 3. Enable SOFT billing
    # ----------------------------------------------------------

    async with SessionLocal() as db:

        state = await service.soft_enable(
            db,
            paid_provider="groq",
            daily_budget=10.0,
            monthly_budget=100.0,
            admin_id="admin-test-001",
        )

        print()
        print("STEP 2 — SOFT ENABLE")
        print("Paid enabled :", state.paid_enabled)
        print("Mode         :", state.mode)
        print("Provider     :", state.paid_provider)
        print("Daily budget:", state.daily_budget)
        print("Monthly budget:", state.monthly_budget)
        print("Updated by  :", state.updated_by)

    # ----------------------------------------------------------
    # 4. Simulate backend restart
    #
    # Create a completely new BillingPolicy + service.
    # ----------------------------------------------------------

    new_policy = BillingPolicy()

    new_service = AdminBillingService(
        billing_policy=new_policy,
        paid_provider="groq",
    )

    async with SessionLocal() as db:

        state = await new_service.load_from_database(db)

        print()
        print("STEP 3 — RELOAD AFTER SIMULATED RESTART")
        print("Paid enabled :", state.paid_enabled)
        print("Mode         :", state.mode)
        print("Provider     :", state.paid_provider)
        print("Daily budget:", state.daily_budget)
        print("Monthly budget:", state.monthly_budget)
        print("Updated by  :", state.updated_by)

        assert state.paid_enabled is True
        assert state.paid_provider == "groq"
        assert state.daily_budget == 10.0
        assert state.monthly_budget == 100.0

    # ----------------------------------------------------------
    # 5. Verify audit logs
    # ----------------------------------------------------------

    async with SessionLocal() as db:

        logs = await AIBillingRepository.get_audit_logs(
            db,
            limit=10,
        )

        print()
        print("STEP 4 — AUDIT LOGS")
        print("Number of logs:", len(logs))

        for log in logs:
            print(
                " -",
                log.action,
                "|",
                log.previous_mode,
                "→",
                log.new_mode,
                "| admin:",
                log.admin_id,
            )

        assert any(
            log.action == "SOFT_ENABLE"
            and log.admin_id == "admin-test-001"
            for log in logs
        )

    # ----------------------------------------------------------
    # 6. Disable billing
    # ----------------------------------------------------------

    async with SessionLocal() as db:

        state = await new_service.disable(
            db,
            admin_id="admin-test-001",
        )

        print()
        print("STEP 5 — DISABLE BILLING")
        print("Paid enabled :", state.paid_enabled)
        print("Mode         :", state.mode)
        print(
            "Can use paid:",
            new_service.can_use_paid(),
        )

        assert state.paid_enabled is False
        assert new_service.can_use_paid() is False

    # ----------------------------------------------------------
    # 7. Verify final persisted state
    # ----------------------------------------------------------

    final_policy = BillingPolicy()

    final_service = AdminBillingService(
        billing_policy=final_policy,
    )

    async with SessionLocal() as db:

        state = await final_service.load_from_database(db)

        print()
        print("STEP 6 — FINAL DATABASE STATE")
        print("Paid enabled :", state.paid_enabled)
        print("Mode         :", state.mode)
        print("Provider     :", state.paid_provider)
        print("Daily budget:", state.daily_budget)
        print("Monthly budget:", state.monthly_budget)

        assert state.paid_enabled is False

    print()
    print("=" * 60)
    print("AI BILLING POSTGRESQL PERSISTENCE TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
