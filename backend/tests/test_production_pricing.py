from __future__ import annotations

from app.services.ai.pricing import create_pricing_registry


def print_case(title: str) -> None:
    print()
    print("=" * 60)
    print(title)
    print("=" * 60)


def main() -> None:

    print("=" * 60)
    print("PRODUCTION AI PRICING TEST")
    print("=" * 60)

    registry = create_pricing_registry()

    # ==========================================================
    # CASE 1 — GROQ
    # ==========================================================

    print_case("CASE 1 — GROQ")

    groq = registry.get(
        provider="groq",
        model="llama-3.1-8b-instant",
    )

    assert groq.input_price_per_million == 0.05
    assert groq.output_price_per_million == 0.08

    print("Model :", "llama-3.1-8b-instant")
    print("Input :", groq.input_price_per_million)
    print("Output:", groq.output_price_per_million)
    print("PASSED")

    # ==========================================================
    # CASE 2 — GEMINI
    # ==========================================================

    print_case("CASE 2 — GEMINI")

    gemini = registry.get(
        provider="gemini",
        model="gemini-3.5-flash",
    )

    assert gemini.input_price_per_million == 1.50
    assert gemini.output_price_per_million == 9.00

    print("Model :", "gemini-3.5-flash")
    print("Input :", gemini.input_price_per_million)
    print("Output:", gemini.output_price_per_million)
    print("PASSED")

    # ==========================================================
    # CASE 3 — OLLAMA
    # ==========================================================

    print_case("CASE 3 — OLLAMA")

    ollama = registry.get(
        provider="ollama",
        model="qwen3:4b",
    )

    assert ollama.input_price_per_million == 0.0
    assert ollama.output_price_per_million == 0.0

    print("Model :", "qwen3:4b")
    print("Input :", ollama.input_price_per_million)
    print("Output:", ollama.output_price_per_million)
    print("PASSED")

    # ==========================================================
    # CASE 4 — UNKNOWN MODEL MUST FAIL
    # ==========================================================

    print_case("CASE 4 — UNKNOWN MODEL")

    try:

        registry.get(
            provider="groq",
            model="unknown-model",
        )

        raise AssertionError(
            "Unknown model should raise KeyError."
        )

    except KeyError:

        print("Unknown model rejected correctly.")
        print("PASSED")

    # ==========================================================
    # COMPLETE
    # ==========================================================

    print()
    print("=" * 60)
    print("PRODUCTION AI PRICING TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    main()