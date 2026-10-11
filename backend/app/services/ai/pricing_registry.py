from __future__ import annotations

from app.services.ai.cost_calculator import ProviderPricing


class PricingRegistry:
    """
    Central registry for LLM token pricing.

    Prices are USD per 1 million tokens.

    The registry is intentionally separate from
    AICostCalculator so pricing can be changed without
    changing cost-calculation logic.
    """

    def __init__(self) -> None:
        self._pricing: dict[
            tuple[str, str],
            ProviderPricing,
        ] = {}

    def register(
        self,
        *,
        provider: str,
        model: str,
        pricing: ProviderPricing,
    ) -> None:
        """
        Register pricing for a provider/model combination.
        """

        provider_key = provider.strip().lower()
        model_key = model.strip()

        if not provider_key:
            raise ValueError(
                "Provider cannot be empty."
            )

        if not model_key:
            raise ValueError(
                "Model cannot be empty."
            )

        self._pricing[
            (provider_key, model_key)
        ] = pricing

    def get(
        self,
        *,
        provider: str,
        model: str,
    ) -> ProviderPricing:
        """
        Return pricing for a provider/model.

        Raises KeyError when pricing has not been
        registered.
        """

        key = (
            provider.strip().lower(),
            model.strip(),
        )

        try:
            return self._pricing[key]
        except KeyError:
            raise KeyError(
                f"No pricing configured for "
                f"provider='{provider}', "
                f"model='{model}'."
            ) from None

    def has(
        self,
        *,
        provider: str,
        model: str,
    ) -> bool:
        """
        Return True when pricing exists.
        """

        key = (
            provider.strip().lower(),
            model.strip(),
        )

        return key in self._pricing

    def clear(self) -> None:
        """
        Clear all registered pricing.

        Primarily useful for tests.
        """

        self._pricing.clear()