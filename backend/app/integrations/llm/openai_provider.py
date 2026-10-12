"""OpenAI Responses adapter. Keys stay on the backend; responses are not stored."""

import json
import httpx
from app.core.settings import get_settings
from app.integrations.llm.base import LLMProvider, LLMResponse, LLMToolCall, LLMUsage


class OpenAIProvider(LLMProvider):
    def __init__(self, *, api_key=None, model=None, client=None):
        settings = get_settings()
        self._key = api_key or settings.OPENAI_API_KEY
        self._model = model or settings.OPENAI_MODEL
        self._client = client
        if not self._key:
            raise ValueError("OpenAI connection is not configured.")

    @property
    def provider_name(self):
        return "openai"

    @property
    def model_name(self):
        return self._model

    async def _request(self, inputs, tools, system_prompt, max_output_tokens):
        body = {
            "model": self._model,
            "input": inputs,
            "store": False,
            "max_output_tokens": min(max_output_tokens, 4096),
        }
        if system_prompt:
            body["instructions"] = system_prompt
        if tools:
            body["tools"] = [
                {
                    "type": "function",
                    "name": t["name"],
                    "description": t.get("description", ""),
                    "parameters": t["parameters"],
                    "strict": False,
                }
                for t in tools
            ]

        async def send(client):
            response = await client.post(
                "https://api.openai.com/v1/responses",
                headers={"Authorization": "Bearer " + self._key},
                json=body,
            )
            response.raise_for_status()
            return response.json()

        if self._client:
            raw = await send(self._client)
        else:
            async with httpx.AsyncClient(timeout=45) as client:
                raw = await send(client)
        if raw.get("status") not in ("completed", "incomplete"):
            raise ValueError("OpenAI returned an unsuccessful response.")
        calls, text = [], []
        for item in raw.get("output", []):
            if item.get("type") == "function_call":
                arguments = json.loads(item.get("arguments", "{}"))
                if not isinstance(arguments, dict):
                    raise ValueError("Invalid tool arguments.")
                calls.append(
                    LLMToolCall(
                        id=item["call_id"], name=item["name"], arguments=arguments
                    )
                )
            if item.get("type") == "message":
                text.extend(
                    part["text"]
                    for part in item.get("content", [])
                    if part.get("type") == "output_text"
                )
        raw["_trav_input"] = (
            inputs
            if isinstance(inputs, list)
            else [{"role": "user", "content": inputs}]
        )
        usage = raw.get("usage") or {}
        return LLMResponse(
            content="\n".join(text),
            provider="openai",
            model=raw.get("model", self._model),
            tool_calls=calls,
            usage=LLMUsage(
                input_tokens=usage.get("input_tokens"),
                output_tokens=usage.get("output_tokens"),
                total_tokens=usage.get("total_tokens"),
            ),
            raw_response=raw,
        )

    async def generate(
        self,
        prompt,
        *,
        system_prompt=None,
        temperature=0.2,
        max_output_tokens=4096,
        **kwargs
    ):
        return await self._request(prompt, [], system_prompt, max_output_tokens)

    async def generate_with_tools(
        self,
        prompt,
        *,
        tools,
        system_prompt=None,
        temperature=0.2,
        max_output_tokens=4096,
        **kwargs
    ):
        return await self._request(
            [{"role": "user", "content": prompt}],
            tools,
            system_prompt,
            max_output_tokens,
        )

    async def continue_with_tool_results(
        self,
        *,
        response,
        tool_results,
        tools,
        system_prompt=None,
        temperature=0.2,
        max_output_tokens=4096,
        **kwargs
    ):
        inputs = list((response.raw_response or {}).get("_trav_input", []))
        # Preserve the original input and every output item, including reasoning.
        raw = response.raw_response or {}
        inputs.extend(raw.get("output", []))
        for call, result in zip(response.tool_calls, tool_results, strict=True):
            inputs.append(
                {
                    "type": "function_call_output",
                    "call_id": call.id,
                    "output": json.dumps(result, default=str),
                }
            )
        return await self._request(inputs, tools, system_prompt, max_output_tokens)
