from __future__ import annotations

from app.services.ai.cost_calculator import ProviderPricing
from app.services.ai.pricing_registry import PricingRegistry


def print_case(title: str) -> None:
    print()
    print("=" * 60)
    print(title)
    print("=" * 60)


def main() -> None:

    print("=" * 60)
    print("AI PRICING REGISTRY TEST")
    print("=" * 60)

    registry = PricingRegistry()

    # ==========================================================
    # CASE 1 — REGISTER AND GET
    # ==========================================================

    print_case("CASE 1 — REGISTER AND GET")

    pricing = ProviderPricing(
        input_price_per_million=1.0,
        output_price_per_million=2.0,
    )

    registry.register(
        provider="groq",
        model="test-model",
        pricing=pricing,
    )

    result = registry.get(
        provider="groq",
        model="test-model",
    )

    assert result is pricing
    assert result.input_price_per_million == 1.0
    assert result.output_price_per_million == 2.0

    print("Provider: groq")
    print("Model   : test-model")
    print("Input   :", result.input_price_per_million)
    print("Output  :", result.output_price_per_million)
    print("PASSED")

    # ==========================================================
    # CASE 2 — PROVIDER CASE NORMALIZATION
    # ==========================================================

    print_case("CASE 2 — PROVIDER CASE NORMALIZATION")

    result = registry.get(
        provider="GROQ",
        model="test-model",
    )

    assert result is pricing

    print("GROQ lookup successful")
    print("PASSED")

    # ==========================================================
    # CASE 3 — HAS
    # ==========================================================

    print_case("CASE 3 — HAS")

    assert registry.has(
        provider="groq",
        model="test-model",
    ) is True

    assert registry.has(
        provider="gemini",
        model="unknown-model",
    ) is False

    print("Registered model: True")
    print("Unknown model   : False")
    print("PASSED")

    # ==========================================================
    # CASE 4 — UNKNOWN MODEL
    # ==========================================================

    print_case("CASE 4 — UNKNOWN MODEL")

    try:

        registry.get(
            provider="groq",
            model="unknown-model",
        )

        raise AssertionError(
            "Expected KeyError"
        )

    except KeyError as exc:

        assert "No pricing configured" in str(exc)

        print("KeyError raised correctly")
        print("PASSED")

    # ==========================================================
    # CASE 5 — OLLAMA ZERO-COST ENTRY
    # ==========================================================

    print_case("CASE 5 — OLLAMA ZERO COST")

    ollama_pricing = ProviderPricing(
        input_price_per_million=0.0,
        output_price_per_million=0.0,
    )

    registry.register(
        provider="ollama",
        model="qwen3:4b",
        pricing=ollama_pricing,
    )

    result = registry.get(
        provider="ollama",
        model="qwen3:4b",
    )

    assert result.input_price_per_million == 0.0
    assert result.output_price_per_million == 0.0

    print("Ollama input price : 0.0")
    print("Ollama output price: 0.0")
    print("PASSED")

    # ==========================================================
    # COMPLETE
    # ==========================================================

    print()
    print("=" * 60)
    print("AI PRICING REGISTRY TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    main()