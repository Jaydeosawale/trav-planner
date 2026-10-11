from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone


@dataclass
class ProviderQuota:
    """
    Current known quota state for one AI provider.

    IMPORTANT:
    This object stores information known from the provider.
    It must never invent quota or reset information.
    """

    provider: str
    model: str

    # Whether the provider currently has known free capacity.
    free_available: bool = True

    # Provider-reported remaining capacity.
    remaining_requests: int | None = None
    remaining_tokens: int | None = None

    # Known reset timestamp.
    #
    # None means the provider has not supplied enough information
    # for us to determine the reset time.
    reset_at: datetime | None = None

    # Why the provider became unavailable.
    #
    # Examples:
    #   "requests"
    #   "tokens"
    #   "daily_quota"
    #   "rate_limit"
    #   "unknown"
    exhausted_reason: str | None = None

    # Last time this state was updated.
    last_checked_at: datetime | None = None

    def normalize_reset_timezone(self) -> None:
        """
        Ensure reset_at is timezone-aware.

        Naive timestamps are interpreted as UTC because the
        application internally works with UTC.
        """

        if self.reset_at is None:
            return

        if self.reset_at.tzinfo is None:
            self.reset_at = self.reset_at.replace(
                tzinfo=timezone.utc
            )

    def is_reset(self) -> bool:
        """
        Return True when a known reset timestamp has arrived.
        """

        if self.reset_at is None:
            return False

        self.normalize_reset_timezone()

        return (
            datetime.now(timezone.utc)
            >= self.reset_at
        )

    def refresh_reset_state(self) -> None:
        """
        Automatically restore free availability when a known
        reset time has been reached.

        We only do this when reset_at is explicitly known.

        We NEVER assume a provider has reset when reset_at is None.
        """

        if not self.is_reset():
            return

        self.free_available = True

        self.remaining_requests = None
        self.remaining_tokens = None

        self.reset_at = None
        self.exhausted_reason = None

        self.last_checked_at = (
            datetime.now(timezone.utc)
        )

    def minutes_until_reset(self) -> int | None:
        """
        Return approximate minutes until the known reset.

        None means the reset time is unknown.

        If the reset time has already arrived, return 0.
        """

        if self.reset_at is None:
            return None

        self.normalize_reset_timezone()

        now = datetime.now(timezone.utc)

        seconds = (
            self.reset_at - now
        ).total_seconds()

        if seconds <= 0:
            return 0

        # Round upward so the displayed value never claims
        # the quota resets earlier than it actually does.
        return int((seconds + 59) // 60)


class QuotaManager:
    """
    Central manager for AI provider quota state.

    Responsibilities:

        - Store provider quota state.
        - Update provider quota state.
        - Detect known reset times.
        - Automatically restore FREE availability
          after a known reset.
        - Find currently available free providers.
        - Find the nearest known reset.

    IMPORTANT:

    This class does NOT call provider APIs.

    Provider integrations are responsible for extracting
    quota information and updating this manager.
    """

    def __init__(self) -> None:
        self._quotas: dict[str, ProviderQuota] = {}

    # ==========================================================
    # UPDATE
    # ==========================================================

    def update(
        self,
        quota: ProviderQuota,
    ) -> None:
        """
        Store/update provider quota information.
        """

        quota.normalize_reset_timezone()

        quota.last_checked_at = (
            datetime.now(timezone.utc)
        )

        self._quotas[
            quota.provider.lower()
        ] = quota

    # ==========================================================
    # GET
    # ==========================================================

    def get(
        self,
        provider: str,
    ) -> ProviderQuota | None:
        """
        Return quota information for a provider.

        Before returning it, check whether its known reset time
        has already arrived.
        """

        provider = provider.lower()

        quota = self._quotas.get(provider)

        if quota is None:
            return None

        quota.refresh_reset_state()

        return quota
    

    def refresh_resets(self) -> None:
        """
        Automatically restore providers whose known free quota
        reset time has passed.

        This does not invent quota information. It only changes
        an exhausted provider back to available when its known
        reset_at has been reached.
        """

        now = datetime.now(timezone.utc)

        for quota in self._quotas.values():

            if quota.free_available:
                continue

            if quota.reset_at is None:
                continue

            reset_at = quota.reset_at

            if reset_at.tzinfo is None:
                reset_at = reset_at.replace(
                    tzinfo=timezone.utc
                )

            if reset_at <= now:
                quota.free_available = True
                quota.remaining_requests = None
                quota.remaining_tokens = None
                quota.reset_at = None
    # ==========================================================
    # ALL
    # ==========================================================

    def all(self) -> list[ProviderQuota]:
        """
        Return all known provider quotas.

        Reset states are refreshed before returning.
        """

        for quota in self._quotas.values():
            quota.refresh_reset_state()

        return list(
            self._quotas.values()
        )

    # ==========================================================
    # FREE PROVIDERS
    # ==========================================================

    def available_free(
        self,
        providers: list[str],
    ) -> list[ProviderQuota]:
        """
        Return free providers currently known to be available.

        Providers whose known reset time has passed are
        automatically restored before selection.
        """

        self.refresh_resets()

        result: list[ProviderQuota] = []

        for provider in providers:
            quota = self._quotas.get(provider)

            if quota is None:
                continue

            if quota.free_available:
                result.append(quota)

        return result
    # ==========================================================
    # NEAREST RESET
    # ==========================================================

    def nearest_reset(
        self,
        providers: list[str],
    ) -> ProviderQuota | None:
        """
        Find the exhausted provider with the closest known
        free-quota reset time.
        """

        self.refresh_resets()

        candidates: list[ProviderQuota] = []

        for provider in providers:
            quota = self._quotas.get(provider)

            if quota is None:
                continue

            if quota.free_available:
                continue

            if quota.reset_at is None:
                continue

            candidates.append(quota)

        if not candidates:
            return None

        return min(
            candidates,
            key=lambda quota: quota.reset_at,
        )
    # ==========================================================
    # MARK EXHAUSTED
    # ==========================================================

    def mark_exhausted(
        self,
        *,
        provider: str,
        model: str,
        reset_at: datetime | None = None,
        remaining_requests: int | None = None,
        remaining_tokens: int | None = None,
        reason: str | None = None,
    ) -> ProviderQuota:
        """
        Mark a provider's free capacity as exhausted.

        reset_at MUST come from reliable provider information.

        Passing reset_at=None is allowed and means the reset
        time is currently unknown.
        """

        quota = ProviderQuota(
            provider=provider.lower(),
            model=model,
            free_available=False,
            remaining_requests=remaining_requests,
            remaining_tokens=remaining_tokens,
            reset_at=reset_at,
            exhausted_reason=reason or "unknown",
        )

        self.update(quota)

        return quota

    # ==========================================================
    # MARK AVAILABLE
    # ==========================================================

    def mark_available(
        self,
        *,
        provider: str,
        model: str,
        remaining_requests: int | None = None,
        remaining_tokens: int | None = None,
    ) -> ProviderQuota:
        """
        Explicitly mark a provider as available.

        This should be called when provider integration has
        reliable evidence that free capacity is available.
        """

        quota = ProviderQuota(
            provider=provider.lower(),
            model=model,
            free_available=True,
            remaining_requests=remaining_requests,
            remaining_tokens=remaining_tokens,
            reset_at=None,
            exhausted_reason=None,
        )

        self.update(quota)

        return quota
