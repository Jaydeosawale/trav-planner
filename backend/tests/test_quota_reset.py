from datetime import datetime, timedelta, timezone

from app.services.ai.quota_manager import (
    ProviderQuota,
    QuotaManager,
)


manager = QuotaManager()

# ----------------------------------------------------------
# Provider exhausted.
# Reset is deliberately in the past.
# ----------------------------------------------------------

manager.update(
    ProviderQuota(
        provider="gemini",
        model="gemini-3.5-flash",
        free_available=False,
        reset_at=(
            datetime.now(timezone.utc)
            - timedelta(minutes=1)
        ),
        exhausted_reason="daily_quota",
    )
)

quota = manager.get("gemini")

print()
print("========== QUOTA RESET TEST ==========")
print("Provider:", quota.provider)
print("Free available:", quota.free_available)
print("Reset at:", quota.reset_at)
print("Reason:", quota.exhausted_reason)
print("Minutes:", quota.minutes_until_reset())
print("=======================================")
