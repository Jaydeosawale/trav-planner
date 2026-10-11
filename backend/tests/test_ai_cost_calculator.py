from __future__ import annotations

from app.integrations.llm.base import LLMUsage
from app.services.ai.cost_calculator import (
    AICostCalculator,
    ProviderPricing,
)


def print_case(title: str) -> None:
    print()
    print("=" * 60)
    print(title)
    print("=" * 60)


def main() -> None:

    print("=" * 60)
    print("AI COST CALCULATOR TEST")
    print("=" * 60)

    # ==========================================================
    # CASE 1 — BASIC COST CALCULATION
    # ==========================================================

    print_case("CASE 1 — BASIC COST CALCULATION")

    usage = LLMUsage(
        input_tokens=1_000_000,
        output_tokens=500_000,
        total_tokens=1_500_000,
    )

    pricing = ProviderPricing(
        input_price_per_million=1.0,
        output_price_per_million=2.0,
    )

    cost = AICostCalculator.calculate(
        usage,
        pricing,
    )

    assert cost.input_tokens == 1_000_000
    assert cost.output_tokens == 500_000
    assert cost.total_tokens == 1_500_000

    assert cost.input_cost == 1.0
    assert cost.output_cost == 1.0
    assert cost.total_cost == 2.0

    print("Input tokens :", cost.input_tokens)
    print("Output tokens:", cost.output_tokens)
    print("Total tokens :", cost.total_tokens)
    print("Input cost   :", cost.input_cost)
    print("Output cost  :", cost.output_cost)
    print("Total cost   :", cost.total_cost)
    print("PASSED")

    # ==========================================================
    # CASE 2 — SMALL REQUEST
    # ==========================================================

    print_case("CASE 2 — SMALL REQUEST")

    usage = LLMUsage(
        input_tokens=10_000,
        output_tokens=2_000,
        total_tokens=12_000,
    )

    pricing = ProviderPricing(
        input_price_per_million=0.50,
        output_price_per_million=1.50,
    )

    cost = AICostCalculator.calculate(
        usage,
        pricing,
    )

    expected_input = 0.005
    expected_output = 0.003
    expected_total = 0.008

    assert abs(
        cost.input_cost - expected_input
    ) < 1e-12

    assert abs(
        cost.output_cost - expected_output
    ) < 1e-12

    assert abs(
        cost.total_cost - expected_total
    ) < 1e-12

    print("Input cost :", cost.input_cost)
    print("Output cost:", cost.output_cost)
    print("Total cost :", cost.total_cost)
    print("PASSED")

    # ==========================================================
    # CASE 3 — MISSING USAGE
    # ==========================================================

    print_case("CASE 3 — MISSING USAGE")

    usage = LLMUsage()

    pricing = ProviderPricing(
        input_price_per_million=1.0,
        output_price_per_million=2.0,
    )

    cost = AICostCalculator.calculate(
        usage,
        pricing,
    )

    assert cost.input_tokens == 0
    assert cost.output_tokens == 0
    assert cost.total_tokens == 0
    assert cost.input_cost == 0.0
    assert cost.output_cost == 0.0
    assert cost.total_cost == 0.0

    print("Input tokens :", cost.input_tokens)
    print("Output tokens:", cost.output_tokens)
    print("Total tokens :", cost.total_tokens)
    print("Total cost   :", cost.total_cost)
    print("PASSED")

    # ==========================================================
    # CASE 4 — TOTAL TOKENS FALLBACK
    # ==========================================================

    print_case("CASE 4 — TOTAL TOKENS FALLBACK")

    usage = LLMUsage(
        input_tokens=7_000,
        output_tokens=3_000,
        total_tokens=None,
    )

    pricing = ProviderPricing(
        input_price_per_million=1.0,
        output_price_per_million=1.0,
    )

    cost = AICostCalculator.calculate(
        usage,
        pricing,
    )

    assert cost.total_tokens == 10_000
    assert cost.total_cost == 0.01

    print("Input tokens :", cost.input_tokens)
    print("Output tokens:", cost.output_tokens)
    print("Total tokens :", cost.total_tokens)
    print("Total cost   :", cost.total_cost)
    print("PASSED")

    # ==========================================================
    # CASE 5 — ZERO PRICING
    # ==========================================================

    print_case("CASE 5 — ZERO PRICING")

    usage = LLMUsage(
        input_tokens=100_000,
        output_tokens=50_000,
        total_tokens=150_000,
    )

    pricing = ProviderPricing(
        input_price_per_million=0.0,
        output_price_per_million=0.0,
    )

    cost = AICostCalculator.calculate(
        usage,
        pricing,
    )

    assert cost.total_cost == 0.0

    print("Total cost:", cost.total_cost)
    print("PASSED")

    # ==========================================================
    # COMPLETE
    # ==========================================================

    print()
    print("=" * 60)
    print("AI COST CALCULATOR TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    main()