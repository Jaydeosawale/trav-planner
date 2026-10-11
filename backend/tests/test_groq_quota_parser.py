from app.integrations.llm.quota.groq import (
    parse_groq_quota_headers,
)


def show(title, headers):

    result = parse_groq_quota_headers(
        headers,
        model="llama-3.3-70b-versatile",
    )

    print()
    print("=" * 60)
    print(title)
    print("=" * 60)

    print("Provider:", result["provider"])
    print("Model:", result["model"])
    print(
        "Free available:",
        result["free_available"],
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
    print(
        "Reason:",
        result["exhausted_reason"],
    )


# ----------------------------------------------------------
# CASE 1 — Plenty of capacity
# ----------------------------------------------------------

show(
    "CASE 1 — GROQ AVAILABLE",
    {
        "x-ratelimit-remaining-requests": "100",
        "x-ratelimit-remaining-tokens": "50000",
        "x-ratelimit-reset-requests": "1m",
        "x-ratelimit-reset-tokens": "30s",
    },
)


# ----------------------------------------------------------
# CASE 2 — Requests exhausted
# ----------------------------------------------------------

show(
    "CASE 2 — REQUEST LIMIT EXHAUSTED",
    {
        "x-ratelimit-remaining-requests": "0",
        "x-ratelimit-remaining-tokens": "50000",
        "x-ratelimit-reset-requests": "42s",
    },
)


# ----------------------------------------------------------
# CASE 3 — Tokens exhausted
# ----------------------------------------------------------

show(
    "CASE 3 — TOKEN LIMIT EXHAUSTED",
    {
        "x-ratelimit-remaining-requests": "100",
        "x-ratelimit-remaining-tokens": "0",
        "x-ratelimit-reset-tokens": "90s",
    },
)


# ----------------------------------------------------------
# CASE 4 — Retry-After
# ----------------------------------------------------------

show(
    "CASE 4 — RETRY AFTER",
    {
        "x-ratelimit-remaining-requests": "0",
        "retry-after": "7s",
    },
)


# ----------------------------------------------------------
# CASE 5 — No quota information
# ----------------------------------------------------------

show(
    "CASE 5 — UNKNOWN QUOTA",
    {},
)
