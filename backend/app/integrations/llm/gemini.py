from __future__ import annotations

from typing import Any

from google import genai
from google.genai import types

from app.core.settings import get_settings
from app.integrations.llm.base import (
    LLMProvider,
    LLMResponse,
    LLMToolCall,
    LLMUsage,
)
from app.services.ai.quota_manager import QuotaManager
from app.integrations.llm.quota.gemini import (
    parse_gemini_quota_error,
)
from app.services.ai.quota_manager import (
    ProviderQuota,
    QuotaManager,
)

class GeminiProvider(LLMProvider):

    def __init__(
        self,
        *,
        api_key: str | None = None,
        model: str | None = None,
        quota_manager: QuotaManager | None = None,
    ) -> None:

        settings = get_settings()

        self._quota_manager = quota_manager
        self._api_key = api_key or settings.GEMINI_API_KEY
        self._model = model or settings.GEMINI_MODEL

        if not self._api_key:
            raise ValueError(
                "GEMINI_API_KEY is required to use GeminiProvider."
            )

        self._client = genai.Client(
            api_key=self._api_key,
        )

    # ==========================================================
    # PROVIDER INFORMATION
    # ==========================================================

    @staticmethod
    def _extract_usage(
        response: Any,
    ) -> LLMUsage:

        usage = getattr(
            response,
            "usage_metadata",
            None,
        )

        if usage is None:
            return LLMUsage()

        input_tokens = getattr(
            usage,
            "prompt_token_count",
            None,
        )

        output_tokens = getattr(
            usage,
            "candidates_token_count",
            None,
        )

        total_tokens = getattr(
            usage,
            "total_token_count",
            None,
        )

        return LLMUsage(
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            total_tokens=total_tokens,
        )

    @property
    def provider_name(self) -> str:
        return "gemini"

    @property
    def model_name(self) -> str:
        return self._model

    # ==========================================================
    # QUOTA TRACKING
    # ==========================================================
    # ==========================================================
    # QUOTA TRACKING
    # ==========================================================

    def _update_quota_available(
        self,
        response: Any,
    ) -> None:
        """
        Mark Gemini as available after a successful response.

        We do not invent remaining request/token counts because
        the Gemini response may not expose them.
        """

        if self._quota_manager is None:
            return

        self._quota_manager.update(
            ProviderQuota(
                provider=self.provider_name,
                model=self.model_name,
                free_available=True,
                remaining_requests=None,
                remaining_tokens=None,
                reset_at=None,
            )
        )

    def _update_quota_from_error(
        self,
        error: Exception,
    ) -> None:
        """
        Convert a Gemini quota error into normalized quota state.

        No reset time is invented. The parser only supplies one
        when Gemini provides enough information.
        """

        if self._quota_manager is None:
            return

        quota = parse_gemini_quota_error(
            error,
            provider=self.provider_name,
            model=self.model_name,
        )

        # Normal non-quota errors must not make Gemini unavailable.
        if not quota["is_quota_error"]:
            return

        self._quota_manager.update(
            ProviderQuota(
                provider=quota["provider"],
                model=quota["model"],
                free_available=quota[
                    "free_available"
                ],
                remaining_requests=quota[
                    "remaining_requests"
                ],
                remaining_tokens=quota[
                    "remaining_tokens"
                ],
                reset_at=quota[
                    "reset_at"
                ],
            )
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
        """
        Generate a normal text response from Gemini.
        """

        config = types.GenerateContentConfig(
            temperature=temperature,
            max_output_tokens=max_output_tokens,
            thinking_config=types.ThinkingConfig(
                thinking_level="minimal",
            ),
        )

        if system_prompt:
            config.system_instruction = system_prompt

        try:
            response = (
                await self._client.aio.models.generate_content(
                    model=self._model,
                    contents=prompt,
                    config=config,
                )
            )

            self._update_quota_available(
                response
            )

        except Exception as exc:
            self._update_quota_from_error(
                exc
            )
            raise
        content = self._extract_text(response)

        if not content:
            self._debug_empty_response(response)

            raise RuntimeError(
                "Gemini returned no text content."
            )

        return LLMResponse(
           content=content,
           provider=self.provider_name,
           model=self.model_name,
           usage=self._extract_usage(response),
           raw_response=response,
           )

    # ==========================================================
    # TOOL / FUNCTION CALLING
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
        """
        Ask Gemini whether it needs to call one of the supplied tools.

        IMPORTANT:

        Gemini only decides which tool to call.

        Trav Planner executes the actual tool through ToolExecutor.
        """

        gemini_tool = self._build_gemini_tool(tools)

        config = self._build_tool_config(
            gemini_tool=gemini_tool,
            system_prompt=system_prompt,
            temperature=temperature,
            max_output_tokens=max_output_tokens,
        )

        try:
            response = (
                await self._client.aio.models.generate_content(
                    model=self._model,
                    contents=prompt,
                    config=config,
                )
            )

            self._update_quota_available(
                response
            )

        except Exception as exc:
            self._update_quota_from_error(
                exc
            )
            raise
        tool_calls = self._extract_tool_calls(response)
        content = self._extract_text(response)

        return LLMResponse(
         content=content,
         provider=self.provider_name,
         model=self.model_name,
         tool_calls=tool_calls,
         usage=self._extract_usage(response),
         raw_response=response,
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
        """
        Continue Gemini generation after Trav Planner tools
        have been executed.

        Flow:

            user prompt
                ↓
            Gemini function call
                ↓
            Trav Planner executes tool
                ↓
            function response
                ↓
            Gemini final answer

        The original Gemini model content is preserved because
        it contains the function-call part and, for Gemini 3
        reasoning models, potentially thought-signature data.
        """

        original_response = response.raw_response

        if original_response is None:
            raise ValueError(
                "Cannot continue Gemini response because "
                "raw_response is missing."
            )

        # ------------------------------------------------------
        # Get original Gemini candidate
        # ------------------------------------------------------

        candidates = getattr(
            original_response,
            "candidates",
            None,
        ) or []

        if not candidates:
            raise RuntimeError(
                "Gemini response contains no candidates."
            )

        model_content = getattr(
            candidates[0],
            "content",
            None,
        )

        if model_content is None:
            raise RuntimeError(
                "Gemini response contains no model content."
            )

        # ------------------------------------------------------
        # Build function response parts
        # ------------------------------------------------------

        function_response_parts: list[types.Part] = []

        for result in tool_results:
            tool_name = result.get("tool_name")

            if not tool_name:
                raise ValueError(
                    "Tool result is missing 'tool_name'."
                )

            tool_call_id = result.get("tool_call_id")

            if not tool_call_id:
                raise ValueError(
                    "Tool result is missing 'tool_call_id'."
                )

            tool_data = result.get(
                "result",
                {},
            )

            if tool_data is None:
                tool_data = {}

            if not isinstance(tool_data, dict):
                tool_data = {
                    "result": tool_data,
                }

            # Use the official SDK helper rather than manually
            # constructing FunctionResponse.
            function_response_parts.append(
                types.Part.from_function_response(
                    name=tool_name,
                    response=tool_data,
                )
            )

        if not function_response_parts:
            raise ValueError(
                "No tool results were supplied to Gemini."
            )

        # ------------------------------------------------------
        # Reconstruct conversation
        # ------------------------------------------------------

        contents: list[Any] = []

        original_prompt = kwargs.get(
            "original_prompt"
        )

        if not original_prompt:
            raise ValueError(
                "original_prompt is required when continuing "
                "Gemini after tool execution."
            )

        # User turn
        contents.append(
            types.Content(
                role="user",
                parts=[
                    types.Part.from_text(
                        text=original_prompt
                    )
                ],
            )
        )

        # Exact Gemini model turn.
        #
        # This contains the original function_call and must
        # remain unchanged.
        contents.append(
            model_content
        )

        # Tool result turn.
        #
        # The SDK documentation uses role="tool" for this
        # function-response content.
        contents.append(
            types.Content(
                role="tool",
                parts=function_response_parts,
            )
        )

        # ------------------------------------------------------
        # Re-register tools
        # ------------------------------------------------------

        gemini_tool = self._build_gemini_tool(tools)

        config = self._build_tool_config(
            gemini_tool=gemini_tool,
            system_prompt=system_prompt,
            temperature=temperature,
            max_output_tokens=max_output_tokens,
        )

        # ------------------------------------------------------
        # Ask Gemini for final response
        # ------------------------------------------------------

        try:
            final_response = (
                await self._client.aio.models.generate_content(
                    model=self._model,
                    contents=contents,
                    config=config,
                )
            )

            self._update_quota_available(
                final_response
            )

        except Exception as exc:
            self._update_quota_from_error(
                exc
            )
            raise

        final_tool_calls = self._extract_tool_calls(
            final_response
        )

        content = self._extract_text(
            final_response
        )

        # ------------------------------------------------------
        # Diagnostics
        # ------------------------------------------------------

        if not content and not final_tool_calls:
            self._debug_empty_response(
                final_response
            )

            raise RuntimeError(
                "Gemini returned an empty response after "
                "tool execution."
            )

        return LLMResponse(
          content=content,
          provider=self.provider_name,
          model=self.model_name,
          tool_calls=final_tool_calls,
          usage=self._extract_usage(final_response),
          raw_response=final_response,
)

    # ==========================================================
    # GEMINI TOOL CONFIGURATION
    # ==========================================================

    @staticmethod
    def _build_gemini_tool(
        tools: list[dict[str, Any]],
    ) -> types.Tool:
        """
        Convert Trav Planner tool definitions into Gemini
        FunctionDeclaration objects.
        """

        function_declarations: list[
            types.FunctionDeclaration
        ] = []

        for tool in tools:
            function_declarations.append(
                types.FunctionDeclaration(
                    name=tool["name"],
                    description=tool["description"],
                    parameters_json_schema=tool["parameters"],
                )
            )

        return types.Tool(
            function_declarations=function_declarations
        )

    @staticmethod
    def _build_tool_config(
        *,
        gemini_tool: types.Tool,
        system_prompt: str | None,
        temperature: float,
        max_output_tokens: int,
    ) -> types.GenerateContentConfig:
        """
        Build Gemini configuration for manual function calling.

        Automatic function calling is disabled because Trav Planner
        itself executes tools through ToolExecutor.
        """

        config = types.GenerateContentConfig(
            temperature=temperature,
            max_output_tokens=max_output_tokens,
            tools=[gemini_tool],

            # Trav Planner owns tool execution.
            automatic_function_calling=(
                types.AutomaticFunctionCallingConfig(
                    disable=True,
                )
            ),

            thinking_config=types.ThinkingConfig(
                thinking_level="minimal",
            ),
        )

        if system_prompt:
            config.system_instruction = system_prompt

        return config

    # ==========================================================
    # RESPONSE TEXT EXTRACTION
    # ==========================================================

    @staticmethod
    def _extract_text(
        response: Any,
    ) -> str:
        """
        Extract visible text from a Gemini response.

        Gemini responses containing function calls may have
        an empty response.text, so candidate parts are inspected
        directly.
        """

        content = getattr(
            response,
            "text",
            None,
        )

        if content:
            return content.strip()

        candidates = getattr(
            response,
            "candidates",
            None,
        ) or []

        text_parts: list[str] = []

        for candidate in candidates:
            candidate_content = getattr(
                candidate,
                "content",
                None,
            )

            if not candidate_content:
                continue

            parts = getattr(
                candidate_content,
                "parts",
                None,
            ) or []

            for part in parts:
                text = getattr(
                    part,
                    "text",
                    None,
                )

                if text:
                    text_parts.append(text)

        return "".join(text_parts).strip()

    # ==========================================================
    # TOOL CALL EXTRACTION
    # ==========================================================

    @staticmethod
    def _extract_tool_calls(
        response: Any,
    ) -> list[LLMToolCall]:
        """
        Extract Gemini function calls and normalize them
        into Trav Planner LLMToolCall objects.
        """

        candidates = getattr(
            response,
            "candidates",
            None,
        ) or []

        tool_calls: list[LLMToolCall] = []

        for candidate in candidates:
            candidate_content = getattr(
                candidate,
                "content",
                None,
            )

            if not candidate_content:
                continue

            parts = getattr(
                candidate_content,
                "parts",
                None,
            ) or []

            for part in parts:
                function_call = getattr(
                    part,
                    "function_call",
                    None,
                )

                if not function_call:
                    continue

                name = getattr(
                    function_call,
                    "name",
                    None,
                )

                if not name:
                    continue

                call_id = getattr(
                    function_call,
                    "id",
                    None,
                )

                arguments = getattr(
                    function_call,
                    "args",
                    None,
                ) or {}

                tool_calls.append(
                    LLMToolCall(
                        id=(
                            call_id
                            or f"call_{len(tool_calls) + 1}"
                        ),
                        name=name,
                        arguments=dict(arguments),
                    )
                )

        return tool_calls

    # ==========================================================
    # DEBUGGING
    # ==========================================================

    @staticmethod
    def _debug_empty_response(
        response: Any,
    ) -> None:
        """
        Print useful Gemini diagnostics when no visible text
        is returned.
        """

        print(
            "\n=== GEMINI EMPTY RESPONSE DEBUG ==="
        )

        print(
            "\nResponse:",
            response,
        )

        print(
            "\nResponse text:",
            repr(
                getattr(
                    response,
                    "text",
                    None,
                )
            ),
        )

        print(
            "\nFunction calls:",
            getattr(
                response,
                "function_calls",
                None,
            ),
        )

        candidates = getattr(
            response,
            "candidates",
            None,
        ) or []

        for index, candidate in enumerate(
            candidates
        ):
            print(
                f"\nCandidate {index}:"
            )

            print(
                "Finish reason:",
                getattr(
                    candidate,
                    "finish_reason",
                    None,
                ),
            )

            print(
                "Finish message:",
                getattr(
                    candidate,
                    "finish_message",
                    None,
                ),
            )

            print(
                "Content:",
                getattr(
                    candidate,
                    "content",
                    None,
                ),
            )

            print(
                "Safety ratings:",
                getattr(
                    candidate,
                    "safety_ratings",
                    None,
                ),
            )

        print(
            "\nPrompt feedback:",
            getattr(
                response,
                "prompt_feedback",
                None,
            ),
        )

        print(
            "\n====================================\n"
        )