from datetime import datetime, timedelta, timezone

from app.integrations.llm.gateway import AIGateway

from app.services.ai.billing_policy import (
    BillingPolicy,
    BillingMode,
)

from app.services.ai.quota_manager import (
    ProviderQuota,
)


gateway = AIGateway(
    billing_policy=BillingPolicy(
        paid_enabled=False,
        mode=BillingMode.FREE_ONLY,
    ),
    free_providers=[
        "groq",
        "gemini",
    ],
    paid_provider="groq",
)

now = datetime.now(timezone.utc)

gateway.quota_manager.update(
    ProviderQuota(
        provider="groq",
        model="llama-3.3-70b-versatile",
        free_available=False,
        reset_at=now + timedelta(minutes=42),
    )
)

gateway.quota_manager.update(
    ProviderQuota(
        provider="gemini",
        model="gemini-3.5-flash",
        free_available=False,
        reset_at=now + timedelta(minutes=18),
    )
)


result = gateway.check_request()


print()
print("========== AI GATEWAY ==========")
print("Allowed:", result.allowed)
print("Provider:", result.provider)
print("Mode:", result.mode)
print("Reason:", result.reason)
print("Reset provider:", result.reset_provider)
print("Reset minutes:", result.reset_minutes)
print()
print("USER MESSAGE:")
print(gateway.blocked_message(result))
print("================================")
