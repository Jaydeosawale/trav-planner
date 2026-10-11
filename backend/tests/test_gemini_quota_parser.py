from types import SimpleNamespace

from app.integrations.llm.quota.gemini import (
    parse_gemini_quota_error,
)


def show(title, error):

    result = parse_gemini_quota_error(
        error,
        model="gemini-3.5-flash",
    )

    print()
    print("=" * 60)
    print(title)
    print("=" * 60)

    print(
        "Quota error:",
        result["is_quota_error"],
    )

    print(
        "Free available:",
        result["free_available"],
    )

    print(
        "Reason:",
        result["exhausted_reason"],
    )

    print(
        "Remaining requests:",
        result["remaining_requests"],
    )

    print(
        "Remaining tokens:",
        result["remaining_tokens"],
    )

    print(
        "Reset at:",
        result["reset_at"],
    )


# ----------------------------------------------------------
# CASE 1 — RPM
# ----------------------------------------------------------

show(
    "CASE 1 — REQUEST RATE LIMIT",
    SimpleNamespace(
        status_code=429,
        message=(
            "RESOURCE_EXHAUSTED: "
            "Requests per minute quota exceeded. "
            "Please retry after 7 seconds."
        ),
    ),
)


# ----------------------------------------------------------
# CASE 2 — TOKEN LIMIT
# ----------------------------------------------------------

show(
    "CASE 2 — TOKEN LIMIT",
    SimpleNamespace(
        status_code=429,
        message=(
            "RESOURCE_EXHAUSTED: "
            "Tokens per minute quota exceeded."
        ),
    ),
)


# ----------------------------------------------------------
# CASE 3 — DAILY QUOTA
# ----------------------------------------------------------

show(
    "CASE 3 — DAILY QUOTA",
    SimpleNamespace(
        status_code=429,
        message=(
            "RESOURCE_EXHAUSTED: "
            "Requests per day quota exceeded."
        ),
    ),
)


# ----------------------------------------------------------
# CASE 4 — UNKNOWN RESET
# ----------------------------------------------------------

show(
    "CASE 4 — UNKNOWN RESET",
    SimpleNamespace(
        status_code=429,
        message=(
            "RESOURCE_EXHAUSTED: quota exceeded."
        ),
    ),
)


# ----------------------------------------------------------
# CASE 5 — NORMAL ERROR
# ----------------------------------------------------------

show(
    "CASE 5 — NORMAL ERROR",
    SimpleNamespace(
        status_code=500,
        message=(
            "Internal server error."
        ),
    ),
)
