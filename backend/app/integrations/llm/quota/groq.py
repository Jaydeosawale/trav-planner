from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Mapping


def _parse_reset_seconds(
    value: str | None,
) -> float | None:
    """
    Parse a Groq reset-duration value.

    Groq may expose reset durations such as:

        1s
        500ms
        1m
        2m30s

    Returns seconds, or None when the value cannot be parsed.
    """

    if not value:
        return None

    value = value.strip().lower()

    total_seconds = 0.0
    number = ""

    index = 0

    while index < len(value):

        char = value[index]

        if char.isdigit() or char == ".":
            number += char
            index += 1
            continue

        if not number:
            return None

        try:
            amount = float(number)
        except ValueError:
            return None

        if value.startswith("ms", index):
            total_seconds += amount / 1000.0
            index += 2

        elif char == "s":
            total_seconds += amount
            index += 1

        elif char == "m":
            total_seconds += amount * 60
            index += 1

        elif char == "h":
            total_seconds += amount * 3600
            index += 1

        else:
            return None

        number = ""

    if number:
        return None

    return total_seconds


def parse_groq_quota_headers(
    headers: Mapping[str, str],
    *,
    provider: str = "groq",
    model: str,
) -> dict:
    """
    Convert Groq rate-limit headers into a normalized quota state.

    This function does NOT make an API request.

    It only interprets headers that Groq has already returned.
    """

    normalized = {
        key.lower(): str(value)
        for key, value in headers.items()
    }

    remaining_requests = _first_int(
        normalized,
        [
            "x-ratelimit-remaining-requests",
        ],
    )

    remaining_tokens = _first_int(
        normalized,
        [
            "x-ratelimit-remaining-tokens",
        ],
    )

    reset_requests = normalized.get(
        "x-ratelimit-reset-requests"
    )

    reset_tokens = normalized.get(
        "x-ratelimit-reset-tokens"
    )

    retry_after = normalized.get(
        "retry-after"
    )

    # ----------------------------------------------------------
    # Determine the closest known reset.
    # ----------------------------------------------------------

    reset_candidates: list[float] = []

    for value in (
        reset_requests,
        reset_tokens,
        retry_after,
    ):

        seconds = _parse_reset_seconds(value)

        if seconds is not None:
            reset_candidates.append(seconds)

    reset_at: datetime | None = None

    if reset_candidates:

        reset_at = (
            datetime.now(timezone.utc)
            + timedelta(
                seconds=min(reset_candidates)
            )
        )

    # ----------------------------------------------------------
    # Determine availability.
    # ----------------------------------------------------------

    free_available = True
    exhausted_reason: str | None = None

    if (
        remaining_requests is not None
        and remaining_requests <= 0
    ):
        free_available = False
        exhausted_reason = "requests"

    if (
        remaining_tokens is not None
        and remaining_tokens <= 0
    ):
        free_available = False

        if exhausted_reason:
            exhausted_reason = (
                f"{exhausted_reason}+tokens"
            )
        else:
            exhausted_reason = "tokens"

    return {
        "provider": provider,
        "model": model,
        "free_available": free_available,
        "remaining_requests": remaining_requests,
        "remaining_tokens": remaining_tokens,
        "reset_at": reset_at,
        "exhausted_reason": exhausted_reason,
    }


def _first_int(
    headers: Mapping[str, str],
    keys: list[str],
) -> int | None:

    for key in keys:

        value = headers.get(key)

        if value is None:
            continue

        try:
            return int(value)
        except (TypeError, ValueError):
            continue

    return None
