from __future__ import annotations

import asyncio
from types import SimpleNamespace

from app.integrations.llm.groq import GroqProvider
from app.services.ai.quota_manager import QuotaManager


# ==========================================================
# MOCK GROQ RESPONSE
# ==========================================================

def mock_tool_response():
    """
    Simulates a Groq response where the model requests
    the place_search tool.
    """

    function = SimpleNamespace(
        name="place_search",
        arguments='{"search":"Mumbai","place_type":"restaurant"}',
    )

    tool_call = SimpleNamespace(
        id="call_mock_001",
        function=function,
    )

    message = SimpleNamespace(
        content="",
        tool_calls=[tool_call],
    )

    choice = SimpleNamespace(
        message=message,
    )

    return SimpleNamespace(
        choices=[choice],
        headers={
            "x-ratelimit-remaining-requests": "19",
            "x-ratelimit-remaining-tokens": "49000",
        },
    )


# ==========================================================
# MOCK FINAL RESPONSE
# ==========================================================

def mock_final_response():
    """
    Simulates Groq's final answer after receiving
    the tool result.
    """

    message = SimpleNamespace(
        content=(
            "I found restaurants in Mumbai "
            "from the Trav Planner database."
        ),
        tool_calls=[],
    )

    choice = SimpleNamespace(
        message=message,
    )

    return SimpleNamespace(
        choices=[choice],
        headers={
            "x-ratelimit-remaining-requests": "18",
            "x-ratelimit-remaining-tokens": "48000",
        },
    )


# ==========================================================
# MOCK CLIENT
# ==========================================================

class MockCompletions:

    call_count = 0

    async def create(self, **kwargs):

        self.call_count += 1

        print()
        print("GROQ MOCK REQUEST", self.call_count)
        print("Model:", kwargs.get("model"))
        print("Messages:", len(kwargs.get("messages", [])))
        print(
            "Tools:",
            len(kwargs.get("tools", [])),
        )

        if self.call_count == 1:

            return mock_tool_response()

        return mock_final_response()


class MockChat:

    def __init__(self):
        self.completions = MockCompletions()


class MockClient:

    def __init__(self):
        self.chat = MockChat()


# ==========================================================
# MAIN TEST
# ==========================================================

async def main():

    quota_manager = QuotaManager()

    # ------------------------------------------------------
    # Create provider without invoking its real API client.
    # ------------------------------------------------------

    provider = object.__new__(GroqProvider)

    provider._model = "llama-3.3-70b-versatile"
    provider._quota_manager = quota_manager
    provider._client = MockClient()

    tools = [
        {
            "name": "place_search",
            "description": (
                "Search Trav Planner places."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "search": {
                        "type": "string",
                    },
                    "place_type": {
                        "type": "string",
                    },
                },
            },
        },
        {
            "name": "map_routing",
            "description": (
                "Calculate route between two locations."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "origin_latitude": {
                        "type": "number",
                    },
                    "origin_longitude": {
                        "type": "number",
                    },
                    "destination_latitude": {
                        "type": "number",
                    },
                    "destination_longitude": {
                        "type": "number",
                    },
                },
            },
        },
    ]

    # ======================================================
    # STEP 1 — LLM requests a tool
    # ======================================================

    response = await provider.generate_with_tools(
        "Find restaurants in Mumbai.",
        tools=tools,
        system_prompt=(
            "You are the Trav Planner AI."
        ),
    )

    print()
    print("=" * 60)
    print("STEP 1 — TOOL CALL")
    print("=" * 60)

    print("Provider:", response.provider)
    print("Model:", response.model)
    print("Content:", response.content)

    print("Tool calls:", len(response.tool_calls))

    for call in response.tool_calls:

        print()
        print("Tool ID:", call.id)
        print("Tool name:", call.name)
        print("Arguments:", call.arguments)

    # ======================================================
    # STEP 2 — SIMULATE TOOL EXECUTION
    # ======================================================

    tool_results = [
        {
            "tool_call_id": response.tool_calls[0].id,
            "tool_name": response.tool_calls[0].name,
            "result": {
                "items": [
                    {
                        "name": "Mock Restaurant Mumbai",
                        "place_type": "restaurant",
                        "rating": 4.5,
                    }
                ],
                "total": 1,
            },
        }
    ]

    print()
    print("=" * 60)
    print("STEP 2 — TOOL RESULT")
    print("=" * 60)

    print(tool_results)

    # ======================================================
    # STEP 3 — SEND TOOL RESULT BACK TO GROQ
    # ======================================================

    final_response = (
        await provider.continue_with_tool_results(
            response=response,
            tool_results=tool_results,
            tools=tools,
            system_prompt=(
                "You are the Trav Planner AI."
            ),
        )
    )

    print()
    print("=" * 60)
    print("STEP 3 — FINAL RESPONSE")
    print("=" * 60)

    print("Provider:", final_response.provider)
    print("Model:", final_response.model)
    print("Content:", final_response.content)
    print(
        "Additional tool calls:",
        len(final_response.tool_calls),
    )

    # ======================================================
    # QUOTA STATE
    # ======================================================

    quota = quota_manager.get("groq")

    print()
    print("=" * 60)
    print("QUOTA STATE")
    print("=" * 60)

    if quota:

        print(
            "Provider:",
            quota.provider,
        )

        print(
            "Model:",
            quota.model,
        )

        print(
            "Free available:",
            quota.free_available,
        )

        print(
            "Remaining requests:",
            quota.remaining_requests,
        )

        print(
            "Remaining tokens:",
            quota.remaining_tokens,
        )

        print(
            "Reset:",
            quota.reset_at,
        )

    else:

        print("No quota state recorded.")

    print()
    print("=" * 60)
    print("GROQ TOOL FLOW TEST COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
