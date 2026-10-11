from __future__ import annotations

from app.core.settings import get_settings
from app.integrations.llm.base import LLMProvider
from app.integrations.llm.gemini import GeminiProvider
from app.integrations.llm.groq import GroqProvider
from app.integrations.llm.ollama import OllamaProvider
from app.services.ai.quota_manager import QuotaManager


def get_llm_provider(
    provider: str | None = None,
    *,
    quota_manager: QuotaManager | None = None,
) -> LLMProvider:
    """
    Create the configured LLM provider.

    The explicit provider argument takes precedence over AI_PROVIDER.

    The shared QuotaManager is passed to providers so that
    provider integrations and AIGateway use the same quota state.

    AI_COST_MODE=free prevents paid providers from being
    selected by this factory-level safety check.
    """

    settings = get_settings()

    selected_provider = (
        provider or settings.AI_PROVIDER
    ).strip().lower()

    cost_mode = settings.AI_COST_MODE.strip().lower()

    # ----------------------------------------------------------
    # Cost protection
    # ----------------------------------------------------------

    if (
        cost_mode == "free"
        and selected_provider == "claude"
    ):
        raise ValueError(
            "Claude is disabled while AI_COST_MODE=free."
        )

    # ----------------------------------------------------------
    # Provider selection
    # ----------------------------------------------------------

    if selected_provider == "gemini":

        return GeminiProvider(
            quota_manager=quota_manager,
        )

    if selected_provider == "groq":

        return GroqProvider(
            quota_manager=quota_manager,
        )

    if selected_provider == "ollama":

        return OllamaProvider()

    if selected_provider == "claude":

        raise NotImplementedError(
            "ClaudeProvider has not been implemented yet."
        )

    raise ValueError(
        f"Unsupported AI provider: {selected_provider}"
    )