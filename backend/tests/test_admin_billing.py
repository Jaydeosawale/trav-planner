from app.services.ai.admin_billing_service import (
    AdminBillingService,
)

from app.services.ai.billing_policy import (
    BillingPolicy,
)


def show(title, state):
    print()
    print("=" * 60)
    print(title)
    print("=" * 60)

    print("Paid enabled  :", state.paid_enabled)
    print("Mode          :", state.mode)
    print("Paid provider :", state.paid_provider)
    print("Daily budget  :", state.daily_budget)
    print("Monthly budget:", state.monthly_budget)
    print("Updated by    :", state.updated_by)


service = AdminBillingService(
    billing_policy=BillingPolicy(),
    paid_provider="groq",
)


# ==========================================================
# CASE 1 — DEFAULT
# ==========================================================

show(
    "CASE 1 — DEFAULT BILLING",
    service.get_state(),
)


# ==========================================================
# CASE 2 — SOFT ENABLE
# ==========================================================

state = service.soft_enable(
    paid_provider="groq",
    daily_budget=10.0,
    monthly_budget=100.0,
    admin_id="admin-001",
)

show(
    "CASE 2 — SOFT ENABLE",
    state,
)

print(
    "Can use paid:",
    service.can_use_paid(),
)


# ==========================================================
# CASE 3 — CHANGE PAID PROVIDER
# ==========================================================

state = service.set_paid_provider(
    "gemini",
    admin_id="admin-001",
)

show(
    "CASE 3 — CHANGE PAID PROVIDER",
    state,
)


# ==========================================================
# CASE 4 — HARD ENABLE
# ==========================================================

state = service.hard_enable(
    paid_provider="groq",
    daily_budget=25.0,
    monthly_budget=250.0,
    admin_id="admin-001",
)

show(
    "CASE 4 — HARD ENABLE",
    state,
)


# ==========================================================
# CASE 5 — DISABLE
# ==========================================================

state = service.disable(
    admin_id="admin-001",
)

show(
    "CASE 5 — DISABLE BILLING",
    state,
)

print(
    "Can use paid:",
    service.can_use_paid(),
)
