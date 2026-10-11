from __future__ import annotations

from types import SimpleNamespace

from app.integrations.llm.base import LLMUsage
from app.integrations.llm.groq import GroqProvider
from app.integrations.llm.gemini import GeminiProvider
from app.integrations.llm.ollama import OllamaProvider


def print_case(title: str) -> None:
    print()
    print("=" * 60)
    print(title)
    print("=" * 60)


def main() -> None:

    print("=" * 60)
    print("LLM USAGE NORMALIZATION TEST")
    print("=" * 60)

    # ==========================================================
    # CASE 1 — LLMUsage MODEL
    # ==========================================================

    print_case("CASE 1 — LLMUsage MODEL")

    usage = LLMUsage(
        input_tokens=100,
        output_tokens=50,
        total_tokens=150,
    )

    assert usage.input_tokens == 100
    assert usage.output_tokens == 50
    assert usage.total_tokens == 150
    assert usage.has_usage is True

    print("Input tokens :", usage.input_tokens)
    print("Output tokens:", usage.output_tokens)
    print("Total tokens :", usage.total_tokens)
    print("Has usage    :", usage.has_usage)
    print("PASSED")

    # ==========================================================
    # CASE 2 — GROQ USAGE EXTRACTION
    # ==========================================================

    print_case("CASE 2 — GROQ USAGE EXTRACTION")

    groq_usage = SimpleNamespace(
        prompt_tokens=120,
        completion_tokens=80,
        total_tokens=200,
    )

    groq_response = SimpleNamespace(
        usage=groq_usage,
    )

    extracted = GroqProvider._extract_usage(
        groq_response,
    )

    assert extracted.input_tokens == 120
    assert extracted.output_tokens == 80
    assert extracted.total_tokens == 200
    assert extracted.has_usage is True

    print("Input tokens :", extracted.input_tokens)
    print("Output tokens:", extracted.output_tokens)
    print("Total tokens :", extracted.total_tokens)
    print("Has usage    :", extracted.has_usage)
    print("PASSED")

    # ==========================================================
    # CASE 3 — GEMINI USAGE EXTRACTION
    # ==========================================================

    print_case("CASE 3 — GEMINI USAGE EXTRACTION")

    gemini_usage = SimpleNamespace(
        prompt_token_count=300,
        candidates_token_count=100,
        total_token_count=400,
    )

    gemini_response = SimpleNamespace(
        usage_metadata=gemini_usage,
    )

    extracted = GeminiProvider._extract_usage(
        gemini_response,
    )

    assert extracted.input_tokens == 300
    assert extracted.output_tokens == 100
    assert extracted.total_tokens == 400
    assert extracted.has_usage is True

    print("Input tokens :", extracted.input_tokens)
    print("Output tokens:", extracted.output_tokens)
    print("Total tokens :", extracted.total_tokens)
    print("Has usage    :", extracted.has_usage)
    print("PASSED")

    # ==========================================================
    # CASE 4 — OLLAMA USAGE EXTRACTION
    # ==========================================================

    print_case("CASE 4 — OLLAMA USAGE EXTRACTION")

    ollama_response = {
        "prompt_eval_count": 500,
        "eval_count": 150,
    }

    extracted = OllamaProvider._extract_usage(
        ollama_response,
    )

    assert extracted.input_tokens == 500
    assert extracted.output_tokens == 150
    assert extracted.total_tokens == 650
    assert extracted.has_usage is True

    print("Input tokens :", extracted.input_tokens)
    print("Output tokens:", extracted.output_tokens)
    print("Total tokens :", extracted.total_tokens)
    print("Has usage    :", extracted.has_usage)
    print("PASSED")

    # ==========================================================
    # CASE 5 — MISSING USAGE
    # ==========================================================

    print_case("CASE 5 — MISSING USAGE")

    empty_groq_response = SimpleNamespace(
        usage=None,
    )

    extracted = GroqProvider._extract_usage(
        empty_groq_response,
    )

    assert extracted.input_tokens is None
    assert extracted.output_tokens is None
    assert extracted.total_tokens is None
    assert extracted.has_usage is False

    print("Input tokens :", extracted.input_tokens)
    print("Output tokens:", extracted.output_tokens)
    print("Total tokens :", extracted.total_tokens)
    print("Has usage    :", extracted.has_usage)
    print("PASSED")

    # ==========================================================
    # COMPLETE
    # ==========================================================

    print()
    print("=" * 60)
    print("LLM USAGE NORMALIZATION TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    main()