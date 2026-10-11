from __future__ import annotations

import re
from datetime import datetime, timedelta, timezone
from typing import Any


def _extract_message(error: Any) -> str:
    """
    Extract a useful message from a Gemini SDK exception.
    """

    message = getattr(error, "message", None)

    if message:
        return str(message)

    return str(error)


def _extract_retry_seconds(
    error: Any,
) -> float | None:
    """
    Try to extract a provider-supplied retry delay.

    We only use a reset time when Gemini actually provides
    enough information.

    Returns None when the delay cannot be determined.
    """

    # ----------------------------------------------------------
    # Direct SDK attributes
    # ----------------------------------------------------------

    for attribute in (
        "retry_delay",
        "retry_after",
        "retry_after_seconds",
    ):

        value = getattr(
            error,
            attribute,
            None,
        )

        if value is None:
            continue

        # timedelta
        if isinstance(
            value,
            timedelta,
        ):
            return max(
                value.total_seconds(),
                0.0,
            )

        # numeric seconds
        if isinstance(
            value,
            (int, float),
        ):
            return max(
                float(value),
                0.0,
            )

        # String representation
        parsed = _parse_duration(
            str(value)
        )

        if parsed is not None:
            return parsed

    # ----------------------------------------------------------
    # Search the error message.
    # ----------------------------------------------------------

    message = _extract_message(error)

    # Examples:
    #
    #   retry in 7s
    #   retry after 10 seconds
    #   retryDelay: 7s
    #
    match = re.search(
        r"(?:retry|retry[-_ ]?after|retry[-_ ]?delay)"
        r"[^0-9]{0,30}"
        r"(\d+(?:\.\d+)?)"
        r"\s*(ms|s|sec|secs|second|seconds|m|min|mins|minute|minutes)",
        message,
        flags=re.IGNORECASE,
    )

    if match:

        amount = float(
            match.group(1)
        )

        unit = (
            match.group(2)
            .lower()
        )

        if unit == "ms":
            return amount / 1000.0

        if unit in {
            "s",
            "sec",
            "secs",
            "second",
            "seconds",
        }:
            return amount

        if unit in {
            "m",
            "min",
            "mins",
            "minute",
            "minutes",
        }:
            return amount * 60

    return None


def _parse_duration(
    value: str,
) -> float | None:
    """
    Parse simple duration strings.

    Supported examples:

        7s
        500ms
        2m
        2m30s
    """

    value = value.strip().lower()

    if not value:
        return None

    matches = re.findall(
        r"(\d+(?:\.\d+)?)\s*(ms|s|m|h)",
        value,
    )

    if not matches:
        return None

    total = 0.0

    for amount_text, unit in matches:

        amount = float(
            amount_text
        )

        if unit == "ms":
            total += amount / 1000

        elif unit == "s":
            total += amount

        elif unit == "m":
            total += amount * 60

        elif unit == "h":
            total += amount * 3600

    return total


def _detect_reason(
    message: str,
) -> str:
    """
    Detect the most likely quota category from the Gemini
    error message.

    This is classification only. It does not invent reset times.
    """

    lower = message.lower()

    # Daily/project quota.
    if any(
        term in lower
        for term in (
            "requests per day",
            "request per day",
            "rpd",
            "daily quota",
            "daily limit",
            "per day",
        )
    ):
        return "daily_quota"

    # Token quota.
    if any(
        term in lower
        for term in (
            "tokens per minute",
            "token per minute",
            "tpm",
            "token limit",
            "tokens limit",
        )
    ):
        return "tokens"

    # Request/rate quota.
    if any(
        term in lower
        for term in (
            "requests per minute",
            "request per minute",
            "rpm",
            "rate limit",
            "rate-limit",
            "too many requests",
        )
    ):
        return "requests"

    return "unknown"


def parse_gemini_quota_error(
    error: Any,
    *,
    provider: str = "gemini",
    model: str,
) -> dict[str, Any]:
    """
    Convert a Gemini quota/rate-limit exception into the
    normalized quota structure used by QuotaManager.

    IMPORTANT:

    This function never invents a reset time.

    If Gemini supplies a retry delay, reset_at is calculated
    from that delay.

    Otherwise reset_at remains None.
    """

    message = _extract_message(error)

    status_code = getattr(
        error,
        "status_code",
        None,
    )

    if status_code is None:
        status_code = getattr(
            error,
            "code",
            None,
        )

    # ----------------------------------------------------------
    # Determine whether this is actually a quota/rate error.
    # ----------------------------------------------------------

    lower = message.lower()

    is_quota_error = (
        status_code == 429
        or "resource_exhausted" in lower
        or "resource exhausted" in lower
        or "quota exceeded" in lower
        or "rate limit" in lower
        or "too many requests" in lower
    )

    if not is_quota_error:

        return {
            "provider": provider,
            "model": model,
            "free_available": True,
            "remaining_requests": None,
            "remaining_tokens": None,
            "reset_at": None,
            "exhausted_reason": None,
            "is_quota_error": False,
        }

    # ----------------------------------------------------------
    # Determine quota category.
    # ----------------------------------------------------------

    reason = _detect_reason(
        message
    )

    # ----------------------------------------------------------
    # Determine reset only when provider information exists.
    # ----------------------------------------------------------

    retry_seconds = (
        _extract_retry_seconds(error)
    )

    reset_at: datetime | None = None

    if retry_seconds is not None:

        reset_at = (
            datetime.now(timezone.utc)
            + timedelta(
                seconds=retry_seconds
            )
        )

    return {
        "provider": provider,
        "model": model,
        "free_available": False,
        "remaining_requests": (
            0
            if reason == "requests"
            else None
        ),
        "remaining_tokens": (
            0
            if reason == "tokens"
            else None
        ),
        "reset_at": reset_at,
        "exhausted_reason": reason,
        "is_quota_error": True,
    }
