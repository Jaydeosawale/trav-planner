from __future__ import annotations

from typing import Any

import ollama

from app.core.settings import get_settings
from app.integrations.llm.base import (
    LLMProvider,
    LLMResponse,
    LLMUsage,
)


class OllamaProvider(LLMProvider):
    """
    Local LLM provider using Ollama.

    Intended for local development and offline AI testing.
    """

    def __init__(
        self,
        *,
        base_url: str | None = None,
        model: str | None = None,
        think: bool | None = None,
    ) -> None:

        settings = get_settings()

        self._base_url = (
            base_url or settings.OLLAMA_BASE_URL
        )

        self._model = (
            model or settings.OLLAMA_MODEL
        )

        self._think = (
            settings.OLLAMA_THINK
            if think is None
            else think
        )

        self._client = ollama.AsyncClient(
            host=self._base_url,
        )

    # ==========================================================
    # USAGE HELPERS
    # ==========================================================

    @staticmethod
    def _extract_usage(
        response: Any,
    ) -> LLMUsage:
        """
        Normalize token usage from Ollama.

        Ollama may expose:

            prompt_eval_count
            eval_count

        The response may be either:
            - a dictionary
            - an Ollama response object

        If unavailable, usage remains unknown.
        """

        if isinstance(response, dict):

            input_tokens = response.get(
                "prompt_eval_count"
            )

            output_tokens = response.get(
                "eval_count"
            )

        else:

            input_tokens = getattr(
                response,
                "prompt_eval_count",
                None,
            )

            output_tokens = getattr(
                response,
                "eval_count",
                None,
            )

        total_tokens = None

        if (
            input_tokens is not None
            and output_tokens is not None
        ):
            total_tokens = (
                input_tokens + output_tokens
            )

        return LLMUsage(
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            total_tokens=total_tokens,
        )
    # ==========================================================
    # PROVIDER INFORMATION
    # ==========================================================

    @property
    def provider_name(self) -> str:
        return "ollama"

    @property
    def model_name(self) -> str:
        return self._model

    # ==========================================================
    # NORMAL TEXT GENERATION
    # ==========================================================

    async def generate(
        self,
        prompt: str,
        *,
        system_prompt: str | None = None,
        temperature: float = 0.2,
        max_output_tokens: int = 4096,
        **kwargs: Any,
    ) -> LLMResponse:

        messages: list[dict[str, str]] = []

        if system_prompt:
            messages.append(
                {
                    "role": "system",
                    "content": system_prompt,
                }
            )

        messages.append(
            {
                "role": "user",
                "content": prompt,
            }
        )

        response = await self._client.chat(
            model=self._model,
            messages=messages,
            think=self._think,
            options={
                "temperature": temperature,
                "num_predict": max_output_tokens,
            },
        )

        content = (
            response.message.content
            or ""
        )

        return LLMResponse(
            content=content,
            provider=self.provider_name,
            model=self.model_name,
            usage=self._extract_usage(
                response
            ),
            raw_response=response,
        )