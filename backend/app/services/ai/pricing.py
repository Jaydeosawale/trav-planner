from __future__ import annotations

from app.services.ai.cost_calculator import ProviderPricing
from app.services.ai.pricing_registry import PricingRegistry


def create_pricing_registry() -> PricingRegistry:
    """
    Create the Trav Planner production pricing registry.

    Prices are USD per 1 million tokens.

    IMPORTANT:
    These prices represent the provider's paid API pricing.
    Free-provider requests still produce a $0 application cost
    when the provider is being used under the free allocation.
    """

    registry = PricingRegistry()

    # ==========================================================
    # GROQ
    # ==========================================================
    #
    # Model:
    #   llama-3.1-8b-instant
    #
    # Current provider pricing:
    #   Input  = $0.05 / 1M tokens
    #   Output = $0.08 / 1M tokens
    #

    registry.register(
        provider="groq",
        model="llama-3.1-8b-instant",
        pricing=ProviderPricing(
            input_price_per_million=0.05,
            output_price_per_million=0.08,
        ),
    )

    # ==========================================================
    # GEMINI
    # ==========================================================
    #
    # Model:
    #   gemini-3.5-flash
    #
    # Current standard paid pricing:
    #   Input  = $1.50 / 1M tokens
    #   Output = $9.00 / 1M tokens
    #

    registry.register(
        provider="gemini",
        model="gemini-3.5-flash",
        pricing=ProviderPricing(
            input_price_per_million=1.50,
            output_price_per_million=9.00,
        ),
    )

    # ==========================================================
    # OLLAMA
    # ==========================================================
    #
    # Ollama is treated as zero API-token cost for our current
    # local deployment.
    #

    registry.register(
        provider="ollama",
        model="qwen3:4b",
        pricing=ProviderPricing(
            input_price_per_million=0.0,
            output_price_per_million=0.0,
        ),
    )

    return registry