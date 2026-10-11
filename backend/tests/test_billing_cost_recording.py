from __future__ import annotations

import asyncio

from app.services.ai.billing_policy import (
    BillingMode,
    BillingPolicy,
)


def print_case(title: str) -> None:
    print()
    print("=" * 60)
    print(title)
    print("=" * 60)


def main() -> None:

    print("=" * 60)
    print("BILLING COST RECORDING TEST")
    print("=" * 60)

    # ==========================================================
    # CASE 1 — RECORD COST IN POLICY
    # ==========================================================

    print_case("CASE 1 — RECORD COST")

    policy = BillingPolicy(
        paid_enabled=True,
        mode=BillingMode.SOFT,
        daily_budget=10.0,
        monthly_budget=100.0,
    )

    assert policy.daily_spent == 0.0
    assert policy.monthly_spent == 0.0

    policy.record_cost(0.50)

    assert policy.daily_spent == 0.50
    assert policy.monthly_spent == 0.50

    print("Daily spent  :", policy.daily_spent)
    print("Monthly spent:", policy.monthly_spent)
    print("PASSED")

    # ==========================================================
    # CASE 2 — MULTIPLE COSTS
    # ==========================================================

    print_case("CASE 2 — MULTIPLE COSTS")

    policy.record_cost(1.25)
    policy.record_cost(0.75)

    assert policy.daily_spent == 2.50
    assert policy.monthly_spent == 2.50

    print("Daily spent  :", policy.daily_spent)
    print("Monthly spent:", policy.monthly_spent)
    print("PASSED")

    # ==========================================================
    # CASE 3 — ZERO COST
    # ==========================================================

    print_case("CASE 3 — ZERO COST")

    before_daily = policy.daily_spent
    before_monthly = policy.monthly_spent

    policy.record_cost(0.0)

    assert policy.daily_spent == before_daily
    assert policy.monthly_spent == before_monthly

    print("Daily unchanged  :", policy.daily_spent)
    print("Monthly unchanged:", policy.monthly_spent)
    print("PASSED")

    # ==========================================================
    # CASE 4 — NEGATIVE COST
    # ==========================================================

    print_case("CASE 4 — NEGATIVE COST")

    try:

        policy.record_cost(-1.0)

        raise AssertionError(
            "Negative cost should be rejected."
        )

    except ValueError as exc:

        assert "cannot be negative" in str(exc)

        print("Negative cost rejected correctly.")
        print("PASSED")

    # ==========================================================
    # CASE 5 — BUDGET STATE
    # ==========================================================

    print_case("CASE 5 — BUDGET STATE")

    policy = BillingPolicy(
        paid_enabled=True,
        mode=BillingMode.SOFT,
        daily_budget=5.0,
        monthly_budget=20.0,
        daily_spent=4.0,
        monthly_spent=10.0,
    )

    assert policy.can_use_paid() is True

    policy.record_cost(1.0)

    assert policy.daily_spent == 5.0
    assert policy.monthly_spent == 11.0

    assert policy.can_use_paid() is False

    print("Daily spent  :", policy.daily_spent)
    print("Daily budget :", policy.daily_budget)
    print("Monthly spent:", policy.monthly_spent)
    print("Paid allowed :", policy.can_use_paid())
    print("PASSED")

    # ==========================================================
    # COMPLETE
    # ==========================================================

    print()
    print("=" * 60)
    print("BILLING COST RECORDING TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    main()