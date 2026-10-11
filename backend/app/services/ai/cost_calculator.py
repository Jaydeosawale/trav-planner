from __future__ import annotations

from dataclasses import dataclass

from app.integrations.llm.base import LLMUsage


@dataclass(frozen=True)
class ProviderPricing:
    """
    Token pricing for an LLM provider/model.

    Prices are expressed in USD per 1 million tokens.
    """

    input_price_per_million: float
    output_price_per_million: float

    def __post_init__(self) -> None:
        if self.input_price_per_million < 0:
            raise ValueError(
                "Input token price cannot be negative."
            )

        if self.output_price_per_million < 0:
            raise ValueError(
                "Output token price cannot be negative."
            )


@dataclass(frozen=True)
class AICost:
    """
    Calculated cost for one LLM request.
    """

    input_tokens: int
    output_tokens: int
    total_tokens: int

    input_cost: float
    output_cost: float
    total_cost: float

    currency: str = "USD"


class AICostCalculator:
    """
    Converts normalized LLM token usage into estimated cost.

    This class does not:
        - modify billing state
        - access PostgreSQL
        - modify budgets
        - authorize paid AI

    It only calculates the cost of a request.
    """

    TOKENS_PER_MILLION = 1_000_000

    @staticmethod
    def calculate(
        usage: LLMUsage,
        pricing: ProviderPricing,
    ) -> AICost:
        """
        Calculate request cost from normalized token usage.
        """

        input_tokens = (
            usage.input_tokens
            if usage.input_tokens is not None
            else 0
        )

        output_tokens = (
            usage.output_tokens
            if usage.output_tokens is not None
            else 0
        )

        total_tokens = (
            usage.total_tokens
            if usage.total_tokens is not None
            else input_tokens + output_tokens
        )

        input_cost = (
            input_tokens
            / AICostCalculator.TOKENS_PER_MILLION
        ) * pricing.input_price_per_million

        output_cost = (
            output_tokens
            / AICostCalculator.TOKENS_PER_MILLION
        ) * pricing.output_price_per_million

        total_cost = input_cost + output_cost

        return AICost(
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            total_tokens=total_tokens,
            input_cost=input_cost,
            output_cost=output_cost,
            total_cost=total_cost,
        )