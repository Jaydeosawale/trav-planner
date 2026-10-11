from datetime import datetime, timedelta, timezone

from app.services.ai.billing_policy import (
    BillingPolicy,
    BillingMode,
)

from app.services.ai.quota_manager import (
    ProviderQuota,
    QuotaManager,
)

from app.services.ai.provider_manager import (
    ProviderManager,
)


quota_manager = QuotaManager()

now = datetime.now(timezone.utc)

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

print()
print("========== AI PROVIDER DECISION ==========")
print("Allowed:", decision.allowed)
print("Provider:", decision.provider)
print("Mode:", decision.mode)
print("Reason:", decision.reason)
print("Reset provider:", decision.reset_provider)
print("Reset minutes:", decision.reset_minutes)
print("===========================================")
