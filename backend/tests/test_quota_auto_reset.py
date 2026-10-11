from datetime import datetime, timedelta, timezone

from app.services.ai.quota_manager import (
    ProviderQuota,
    QuotaManager,
)


manager = QuotaManager()

# ----------------------------------------------------------
# Create an already-exhausted provider.
# ----------------------------------------------------------

created_quota = ProviderQuota(
    provider="gemini",
    model="gemini-3.5-flash",
    free_available=False,
    remaining_requests=0,
    reset_at=(
        datetime.now(timezone.utc)
        - timedelta(minutes=1)
    ),
)

manager.update(created_quota)

print("========== BEFORE REFRESH ==========")

# IMPORTANT:
# Use the object we just created.
# manager.get() automatically refreshes the state.
print(
    "Free available:",
    created_quota.free_available,
)

print(
    "Reset:",
    created_quota.reset_at,
)

# ----------------------------------------------------------
# Provider selection triggers automatic reset.
# ----------------------------------------------------------

available = manager.available_free(
    ["gemini"]
)

print()
print("========== AFTER REFRESH ==========")

print(
    "Available providers:",
    [
        quota.provider
        for quota in available
    ],
)

quota = manager.get("gemini")

print(
    "Free available:",
    quota.free_available,
)

print(
    "Reset:",
    quota.reset_at,
)

print(
    "Remaining requests:",
    quota.remaining_requests,
)

print(
    "Remaining tokens:",
    quota.remaining_tokens,
)

print(
    "===================================="
)
