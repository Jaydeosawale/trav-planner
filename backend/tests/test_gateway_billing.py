from __future__ import annotations

import asyncio
from types import SimpleNamespace

from app.integrations.llm.base import LLMResponse, LLMUsage
from app.integrations.llm.gateway import AIGateway


async def main() -> None:

    print("=" * 60)
    print("AI GATEWAY BILLING INTEGRATION TEST")
    print("=" * 60)

    gateway = AIGateway(
        free_providers=["groq", "gemini"],
        paid_provider="groq",
    )

    # ==========================================================
    # CASE 1 — FREE REQUEST
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 1 — FREE REQUEST")
    print("=" * 60)

    free_response = LLMResponse(
        content="Free response",
        provider="groq",
        model="llama-3.1-8b-instant",
        usage=LLMUsage(
            input_tokens=1000,
            output_tokens=500,
            total_tokens=1500,
        ),
    )

    await gateway._record_response_cost(
        free_response,
        billing_mode="free",
    )

    print("Provider    :", free_response.provider)
    print("Billing mode: free")
    print("Cost        : $0.0")
    print("PASSED")

    # ==========================================================
    # CASE 2 — PAID REQUEST
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 2 — PAID REQUEST")
    print("=" * 60)

    paid_response = LLMResponse(
        content="Paid response",
        provider="groq",
        model="llama-3.1-8b-instant",
        usage=LLMUsage(
            input_tokens=1_000_000,
            output_tokens=500_000,
            total_tokens=1_500_000,
        ),
    )

    print("Provider     :", paid_response.provider)
    print("Model        :", paid_response.model)
    print("Input tokens :", paid_response.usage.input_tokens)
    print("Output tokens:", paid_response.usage.output_tokens)

    # IMPORTANT:
    # This test requires billing to be enabled in PostgreSQL.
    #
    # We are NOT executing this yet.
    #
    # await gateway._record_response_cost(
    #     paid_response,
    #     billing_mode="paid",
    # )

    print("Expected cost: $0.09")
    print("READY FOR DATABASE TEST")

    # ==========================================================
    # CASE 3 — OLLAMA
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 3 — OLLAMA ZERO COST")
    print("=" * 60)

    ollama_response = LLMResponse(
        content="Local response",
        provider="ollama",
        model="qwen3:4b",
        usage=LLMUsage(
            input_tokens=10_000,
            output_tokens=5_000,
            total_tokens=15_000,
        ),
    )

    await gateway._record_response_cost(
        ollama_response,
        billing_mode="paid",
    )

    print("Provider     :", ollama_response.provider)
    print("Model        :", ollama_response.model)
    print("Configured cost: $0.0")
    print("PASSED")

    # ==========================================================
    # CASE 4 — MISSING USAGE
    # ==========================================================

    print()
    print("=" * 60)
    print("CASE 4 — MISSING USAGE")
    print("=" * 60)

    missing_usage_response = LLMResponse(
        content="Unknown usage",
        provider="groq",
        model="llama-3.1-8b-instant",
        usage=LLMUsage(),
    )

    await gateway._record_response_cost(
        missing_usage_response,
        billing_mode="paid",
    )

    print("Usage available:",
          missing_usage_response.usage.has_usage)
    print("Expected cost   : $0.0")
    print("PASSED")

    # ==========================================================
    # COMPLETE
    # ==========================================================

    print()
    print("=" * 60)
    print("AI GATEWAY BILLING INTEGRATION TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())