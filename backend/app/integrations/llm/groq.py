from __future__ import annotations

import json
from typing import Any

from groq import AsyncGroq

from app.core.settings import get_settings
from app.integrations.llm.base import (
    LLMProvider,
    LLMResponse,
    LLMToolCall,
    LLMUsage,
)
from app.integrations.llm.quota.groq import (
    parse_groq_quota_headers,
)
from app.services.ai.quota_manager import QuotaManager


class GroqProvider(LLMProvider):
    """
    Groq LLM provider.

    Supports:

        - Normal text generation
        - Native Groq tool/function calling
        - Continuing generation after tool execution
        - Shared QuotaManager integration
        - Groq rate-limit/quota tracking
        - Normalized token usage
    """

    def __init__(
        self,
        *,
        api_key: str | None = None,
        model: str | None = None,
        quota_manager: QuotaManager | None = None,
    ) -> None:

        settings = get_settings()

        self._api_key = (
            api_key or settings.GROQ_API_KEY
        )

        self._model = (
            model or settings.GROQ_MODEL or "openai/gpt-oss-20b"
        )

        self._quota_manager = quota_manager

        if not self._api_key:
            raise ValueError(
                "GROQ_API_KEY is required to use GroqProvider."
            )

        self._client = AsyncGroq(
            api_key=self._api_key,
        )

    # ==========================================================
    # PROVIDER INFORMATION
    # ==========================================================

    @property
    def provider_name(self) -> str:
        return "groq"

    @property
    def model_name(self) -> str:
        return self._model

    def _generation_options(self, limit):
        if self._model.startswith("openai/gpt-oss-"):
            return {"max_completion_tokens": limit, "reasoning_effort": "low"}
        return {"max_tokens": limit}

    # ==========================================================
    # HEADER EXTRACTION
    # ==========================================================

    def _extract_headers(
        self,
        response: Any,
    ) -> dict[str, str]:
        """
        Extract response headers from the Groq SDK response.
        """

        candidates = [
            getattr(response, "headers", None),
            getattr(response, "response_headers", None),
        ]

        raw_response = getattr(
            response,
            "_response",
            None,
        )

        if raw_response is not None:
            candidates.append(
                getattr(
                    raw_response,
                    "headers",
                    None,
                )
            )

        for headers in candidates:

            if headers is None:
                continue

            try:
                return {
                    str(key): str(value)
                    for key, value in headers.items()
                }
            except AttributeError:
                continue

        return {}

    # ==========================================================
    # USAGE HELPERS
    # ==========================================================

    @staticmethod
    def _extract_usage(
        response: Any,
    ) -> LLMUsage:
        """
        Normalize token usage from a Groq response.
        """

        usage = getattr(
            response,
            "usage",
            None,
        )

        if usage is None:
            return LLMUsage()

        input_tokens = getattr(
            usage,
            "prompt_tokens",
            None,
        )

        output_tokens = getattr(
            usage,
            "completion_tokens",
            None,
        )

        total_tokens = getattr(
            usage,
            "total_tokens",
            None,
        )

        return LLMUsage(
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            total_tokens=total_tokens,
        )

    # ==========================================================
    # QUOTA RESPONSE
    # ==========================================================

    def _update_quota_from_response(
        self,
        response: Any,
    ) -> None:
        """
        Update the shared QuotaManager using Groq
        rate-limit response headers.
        """

        if self._quota_manager is None:
            return

        headers = self._extract_headers(
            response
        )

        if not headers:
            return

        try:
            quota = parse_groq_quota_headers(
                headers
            )
        except Exception:
            return

        if not quota:
            return

        remaining_requests = (
            quota.get("remaining_requests")
        )

        remaining_tokens = (
            quota.get("remaining_tokens")
        )

        reset_at = quota.get(
            "reset_at"
        )

        exhausted_reason = quota.get(
            "exhausted_reason"
        )

        if (
            remaining_requests is not None
            and remaining_requests <= 0
        ) or (
            remaining_tokens is not None
            and remaining_tokens <= 0
        ):

            if reset_at is not None:

                self._quota_manager.mark_exhausted(
                    provider=self.provider_name,
                    model=self.model_name,
                    reset_at=reset_at,
                    remaining_requests=(
                        remaining_requests
                    ),
                    remaining_tokens=(
                        remaining_tokens
                    ),
                    reason=(
                        exhausted_reason
                        or "rate_limit"
                    ),
                )

    # ==========================================================
    # QUOTA ERROR
    # ==========================================================

    def _update_quota_from_error(
        self,
        exc: Exception,
    ) -> None:
        """
        Update quota state when Groq reports a
        rate-limit or quota-related error.
        """

        if self._quota_manager is None:
            return

        response = getattr(
            exc,
            "response",
            None,
        )

        if response is None:
            return

        headers = self._extract_headers(
            response
        )

        if not headers:
            return

        try:
            quota = parse_groq_quota_headers(
                headers
            )
        except Exception:
            return

        if not quota:
            return

        reset_at = quota.get(
            "reset_at"
        )

        if reset_at is None:
            return

        self._quota_manager.mark_exhausted(
            provider=self.provider_name,
            model=self.model_name,
            reset_at=reset_at,
            remaining_requests=(
                quota.get(
                    "remaining_requests"
                )
            ),
            remaining_tokens=(
                quota.get(
                    "remaining_tokens"
                )
            ),
            reason=(
                quota.get(
                    "exhausted_reason"
                )
                or "rate_limit"
            ),
        )

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

        messages: list[dict[str, Any]] = []

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

        try:

            response = (
                await self._client.chat.completions.create(
                    model=self._model,
                    messages=messages,
                    temperature=temperature,
                    **self._generation_options(max_output_tokens),
                )
            )

            self._update_quota_from_response(
                response
            )

        except Exception as exc:

            self._update_quota_from_error(
                exc
            )

            raise

        choices = (
            getattr(
                response,
                "choices",
                None,
            )
            or []
        )

        content = ""

        if choices:

            message = getattr(
                choices[0],
                "message",
                None,
            )

            if message is not None:
                content = (
                    getattr(
                        message,
                        "content",
                        None,
                    )
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
            original_prompt=prompt,
        )

    # ==========================================================
    # TOOL SCHEMA CONVERSION
    # ==========================================================

    def _build_tools(
        self,
        tools: list[dict[str, Any]],
    ) -> list[dict[str, Any]]:

        converted: list[dict[str, Any]] = []

        for tool in tools:

            name = tool.get(
                "name",
                "",
            )

            description = tool.get(
                "description",
                "",
            )

            parameters = tool.get(
                "parameters",
                {},
            )

            converted.append(
                {
                    "type": "function",
                    "function": {
                        "name": name,
                        "description": description,
                        "parameters": parameters,
                    },
                }
            )

        return converted

    # ==========================================================
    # TOOL CALL GENERATION
    # ==========================================================

    async def generate_with_tools(
        self,
        prompt: str,
        *,
        tools: list[dict[str, Any]],
        system_prompt: str | None = None,
        temperature: float = 0.2,
        max_output_tokens: int = 4096,
        **kwargs: Any,
    ) -> LLMResponse:

        messages: list[dict[str, Any]] = []

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

        groq_tools = self._build_tools(
            tools
        )

        try:

            response = (
                await self._client.chat.completions.create(
                    model=self._model,
                    messages=messages,
                    tools=groq_tools,
                    tool_choice="auto",
                    temperature=temperature,
                    **self._generation_options(max_output_tokens),
                )
            )

            self._update_quota_from_response(
                response
            )

        except Exception as exc:

            self._update_quota_from_error(
                exc
            )

            raise

        choices = (
            getattr(
                response,
                "choices",
                None,
            )
            or []
        )

        content = ""
        tool_calls: list[LLMToolCall] = []

        if choices:

            message = getattr(
                choices[0],
                "message",
                None,
            )

            if message is not None:

                content = (
                    getattr(
                        message,
                        "content",
                        None,
                    )
                    or ""
                )

                raw_tool_calls = (
                    getattr(
                        message,
                        "tool_calls",
                        None,
                    )
                    or []
                )

                for index, tool_call in enumerate(
                    raw_tool_calls
                ):

                    function = getattr(
                        tool_call,
                        "function",
                        None,
                    )

                    if function is None:
                        continue

                    name = getattr(
                        function,
                        "name",
                        "",
                    )

                    raw_arguments = getattr(
                        function,
                        "arguments",
                        "{}",
                    )

                    if isinstance(
                        raw_arguments,
                        str,
                    ):

                        try:
                            arguments = json.loads(
                                raw_arguments
                            )
                        except json.JSONDecodeError:
                            arguments = {}

                    elif isinstance(
                        raw_arguments,
                        dict,
                    ):
                        arguments = raw_arguments

                    else:
                        arguments = {}

                    call_id = getattr(
                        tool_call,
                        "id",
                        None,
                    )

                    if not call_id:
                        call_id = (
                            f"groq_tool_call_{index}"
                        )

                    tool_calls.append(
                        LLMToolCall(
                            id=str(call_id),
                            name=str(name),
                            arguments=arguments,
                        )
                    )

        return LLMResponse(
            content=content,
            provider=self.provider_name,
            model=self.model_name,
            tool_calls=tool_calls,
            usage=self._extract_usage(
                response
            ),
            raw_response=response,
            original_prompt=prompt,
        )

    # ==========================================================
    # CONTINUE AFTER TOOL EXECUTION
    # ==========================================================

    async def continue_with_tool_results(
        self,
        *,
        response: LLMResponse,
        tool_results: list[dict[str, Any]],
        tools: list[dict[str, Any]],
        system_prompt: str | None = None,
        temperature: float = 0.2,
        max_output_tokens: int = 4096,
        **kwargs: Any,
    ) -> LLMResponse:

        messages: list[dict[str, Any]] = []

        if system_prompt:
            messages.append(
                {
                    "role": "system",
                    "content": system_prompt,
                }
            )

        original_prompt = kwargs.get("original_prompt") or response.original_prompt
        if not original_prompt:
            raise ValueError("The original request is required for tool continuation.")
        messages.append({"role": "user", "content": original_prompt})

        original_response = (
            response.raw_response
        )

        choices = (
            getattr(
                original_response,
                "choices",
                None,
            )
            or []
        )

        assistant_message: dict[str, Any] = {
            "role": "assistant",
            "content": (
                response.content
                or None
            ),
        }

        if choices:

            original_message = getattr(
                choices[0],
                "message",
                None,
            )

            raw_tool_calls = (
                getattr(
                    original_message,
                    "tool_calls",
                    None,
                )
                or []
            )

            assistant_tool_calls = []

            for tool_call in raw_tool_calls:

                function = getattr(
                    tool_call,
                    "function",
                    None,
                )

                if function is None:
                    continue

                assistant_tool_calls.append(
                    {
                        "id": str(
                            getattr(
                                tool_call,
                                "id",
                                "",
                            )
                        ),
                        "type": "function",
                        "function": {
                            "name": getattr(
                                function,
                                "name",
                                "",
                            ),
                            "arguments": getattr(
                                function,
                                "arguments",
                                "{}",
                            ),
                        },
                    }
                )

            if assistant_tool_calls:
                assistant_message[
                    "tool_calls"
                ] = assistant_tool_calls

        messages.append(
            assistant_message
        )

        for result in tool_results:

            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": str(
                        result.get(
                            "tool_call_id",
                            result.get(
                                "id",
                                "",
                            ),
                        )
                    ),
                    "content": json.dumps(
                        result.get(
                            "result",
                            result.get(
                                "content",
                                "",
                            ),
                        )
                    ),
                }
            )

        groq_tools = self._build_tools(
            tools
        )

        try:

            final_response = (
                await self._client.chat.completions.create(
                    model=self._model,
                    messages=messages,
                    tools=groq_tools,
                    tool_choice="none",
                    temperature=temperature,
                    **self._generation_options(max_output_tokens),
                )
            )

            self._update_quota_from_response(
                final_response
            )

        except Exception as exc:

            self._update_quota_from_error(
                exc
            )

            raise

        choices = (
            getattr(
                final_response,
                "choices",
                None,
            )
            or []
        )

        content = ""
        additional_tool_calls: list[
            LLMToolCall
        ] = []

        if choices:

            message = getattr(
                choices[0],
                "message",
                None,
            )

            if message is not None:

                content = (
                    getattr(
                        message,
                        "content",
                        None,
                    )
                    or ""
                )

                raw_tool_calls = (
                    getattr(
                        message,
                        "tool_calls",
                        None,
                    )
                    or []
                )

                for index, tool_call in enumerate(
                    raw_tool_calls
                ):

                    function = getattr(
                        tool_call,
                        "function",
                        None,
                    )

                    if function is None:
                        continue

                    name = getattr(
                        function,
                        "name",
                        "",
                    )

                    raw_arguments = getattr(
                        function,
                        "arguments",
                        "{}",
                    )

                    if isinstance(
                        raw_arguments,
                        str,
                    ):

                        try:
                            arguments = json.loads(
                                raw_arguments
                            )
                        except json.JSONDecodeError:
                            arguments = {}

                    elif isinstance(
                        raw_arguments,
                        dict,
                    ):
                        arguments = raw_arguments

                    else:
                        arguments = {}

                    call_id = getattr(
                        tool_call,
                        "id",
                        None,
                    )

                    if not call_id:
                        call_id = (
                            f"groq_followup_tool_call_{index}"
                        )

                    additional_tool_calls.append(
                        LLMToolCall(
                            id=str(call_id),
                            name=str(name),
                            arguments=arguments,
                        )
                    )

        return LLMResponse(
            content=content,
            provider=self.provider_name,
            model=self.model_name,
            tool_calls=additional_tool_calls,
            usage=self._extract_usage(
                final_response
            ),
            raw_response=final_response,
        )