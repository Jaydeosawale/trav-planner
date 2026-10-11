from datetime import datetime, timedelta, timezone

from app.services.ai.billing_policy import (
    BillingMode,
    BillingPolicy,
)
from app.services.ai.provider_manager import ProviderManager
from app.services.ai.quota_manager import (
    ProviderQuota,
    QuotaManager,
)


def show(title, decision):
    print()
    print("=" * 55)
    print(title)
    print("=" * 55)
    print("Allowed       :", decision.allowed)
    print("Provider      :", decision.provider)
    print("Mode          :", decision.mode)
    print("Reason        :", decision.reason)
    print("Reset provider:", decision.reset_provider)
    print("Reset minutes :", decision.reset_minutes)


now = datetime.now(timezone.utc)


# ==========================================================
# CASE 1
# Groq FREE available
# ==========================================================

quota_manager = QuotaManager()

quota_manager.update(
    ProviderQuota(
        provider="groq",
        model="llama-3.3-70b-versatile",
        free_available=True,
        reset_at=None,
    )
)

quota_manager.update(
    ProviderQuota(
        provider="gemini",
        model="gemini-3.5-flash",
        free_available=True,
        reset_at=None,
    )
)

billing_policy = BillingPolicy(
    paid_enabled=False,
    mode=BillingMode.FREE_ONLY,
)

manager = ProviderManager(
    quota_manager=quota_manager,
    billing_policy=billing_policy,
    free_providers=[
        "groq",
        "gemini",
    ],
    paid_provider="groq",
)

decision = manager.choose()

show(
    "CASE 1 — GROQ FREE AVAILABLE",
    decision,
)


# ==========================================================
# CASE 2
# Groq exhausted
# Gemini FREE available
# ==========================================================

quota_manager = QuotaManager()

quota_manager.update(
    ProviderQuota(
        provider="groq",
        model="llama-3.3-70b-versatile",
        free_available=False,
        reset_at=now + timedelta(minutes=42),
    )
)

quota_manager.update(
    ProviderQuota(
        provider="gemini",
        model="gemini-3.5-flash",
        free_available=True,
        reset_at=None,
    )
)

billing_policy = BillingPolicy(
    paid_enabled=False,
    mode=BillingMode.FREE_ONLY,
)

manager = ProviderManager(
    quota_manager=quota_manager,
    billing_policy=billing_policy,
    free_providers=[
        "groq",
        "gemini",
    ],
    paid_provider="groq",
)

decision = manager.choose()

show(
    "CASE 2 — GROQ EXHAUSTED, GEMINI FREE AVAILABLE",
    decision,
)


# ==========================================================
# CASE 3
# BOTH FREE EXHAUSTED
# ADMIN BILLING OFF
# ==========================================================

quota_manager = QuotaManager()

quota_manager.update(
    ProviderQuota(
        provider="groq",
        model="llama-3.3-70b-versatile",
        free_available=False,
        reset_at=now + timedelta(minutes=42),
    )
)

quota_manager.update(
    ProviderQuota(
        provider="gemini",
        model="gemini-3.5-flash",
        free_available=False,
        reset_at=now + timedelta(minutes=18),
    )
)

billing_policy = BillingPolicy(
    paid_enabled=False,
    mode=BillingMode.FREE_ONLY,
)

manager = ProviderManager(
    quota_manager=quota_manager,
    billing_policy=billing_policy,
    free_providers=[
        "groq",
        "gemini",
    ],
    paid_provider="groq",
)

decision = manager.choose()

show(
    "CASE 3 — ALL FREE EXHAUSTED, BILLING OFF",
    decision,
)


# ==========================================================
# CASE 4
# BOTH FREE EXHAUSTED
# ADMIN BILLING ON
# ==========================================================

quota_manager = QuotaManager()

quota_manager.update(
    ProviderQuota(
        provider="groq",
        model="llama-3.3-70b-versatile",
        free_available=False,
        reset_at=now + timedelta(minutes=42),
    )
)

quota_manager.update(
    ProviderQuota(
        provider="gemini",
        model="gemini-3.5-flash",
        free_available=False,
        reset_at=now + timedelta(minutes=18),
    )
)

billing_policy = BillingPolicy(
    paid_enabled=True,
    mode=BillingMode.SOFT,
)

manager = ProviderManager(
    quota_manager=quota_manager,
    billing_policy=billing_policy,
    free_providers=[
        "groq",
        "gemini",
    ],
    paid_provider="groq",
)

decision = manager.choose()

show(
    "CASE 4 — ALL FREE EXHAUSTED, BILLING ON",
    decision,
)


# ==========================================================
# CASE 5 — FREE QUOTA RESET → RETURN TO FREE
# ==========================================================

from datetime import datetime, timedelta, timezone

print()
print("=" * 55)
print("CASE 5 — FREE QUOTA RESETS → RETURN TO FREE")
print("=" * 55)

# Create a fresh quota manager.
reset_quota_manager = QuotaManager()

# Both providers initially exhausted.
reset_quota_manager.update(
    ProviderQuota(
        provider="groq",
        model="llama-3.3-70b-versatile",
        free_available=False,
        remaining_requests=0,
        reset_at=(
            datetime.now(timezone.utc)
            + timedelta(minutes=30)
        ),
    )
)

reset_quota_manager.update(
    ProviderQuota(
        provider="gemini",
        model="gemini-3.5-flash",
        free_available=False,
        remaining_requests=0,
        reset_at=(
            datetime.now(timezone.utc)
            - timedelta(minutes=1)
        ),
    )
)

# Billing remains enabled.
reset_billing_policy = BillingPolicy(
    paid_enabled=True,
    mode=BillingMode.SOFT,
)

reset_manager = ProviderManager(
    quota_manager=reset_quota_manager,
    billing_policy=reset_billing_policy,
    free_providers=[
        "groq",
        "gemini",
    ],
    paid_provider="groq",
)

reset_decision = reset_manager.choose()

show(
    "CASE 5 — FREE QUOTA RESETS → RETURN TO FREE",
    reset_decision,
)