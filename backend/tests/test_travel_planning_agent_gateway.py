from __future__ import annotations

import asyncio
from types import SimpleNamespace
from typing import Any

from app.agents.base import AgentResponse
from app.agents.travel_planner import TravelPlanningAgent


class FakeBillingPolicy:
    def __init__(self, paid_enabled: bool = False):
        self.paid_enabled = paid_enabled


class FakeGateway:
    """Fake Gateway: no real LLM/API request is made."""

    def __init__(self):
        self.billing_policy = FakeBillingPolicy()
        self.generate_with_tools_calls = 0
        self.continue_with_tool_results_calls = 0
        self.blocked = False
        self.initial_response = None
        self.final_response = None

    async def generate_with_tools(
        self,
        prompt: str,
        *,
        tools: list[dict[str, Any]],
        system_prompt: str | None = None,
        temperature: float = 0.2,
        max_output_tokens: int = 4096,
        **kwargs: Any,
    ):
        self.generate_with_tools_calls += 1

        if self.blocked:
            return (
                SimpleNamespace(
                    allowed=False,
                    provider=None,
                    mode="blocked",
                    content="AI request blocked by billing policy.",
                    reason="Paid AI is not currently authorized.",
                    reset_provider="groq",
                    reset_minutes=30,
                ),
                None,
            )

        return (
            SimpleNamespace(
                allowed=True,
                provider=self.initial_response.provider,
                mode="free",
                content=self.initial_response.content,
                reason="Free AI provider is available.",
                reset_provider=None,
                reset_minutes=None,
            ),
            self.initial_response,
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
        **kwargs,
    ):
        self.continue_with_tool_results_calls += 1

        if self.blocked:
            return (
                SimpleNamespace(
                    allowed=False,
                    provider=None,
                    mode="blocked",
                    content="AI continuation blocked by billing policy.",
                    reason="Paid AI is not currently authorized.",
                    reset_provider="groq",
                    reset_minutes=30,
                ),
                None,
            )

        final = self.final_response

        return (
            SimpleNamespace(
                allowed=True,
                provider=final.provider,
                mode="free",
                content=final.content,
                reason="Free AI provider is available.",
                reset_provider=None,
                reset_minutes=None,
            ),
            final,
        )


async def fake_tool_execute(tool_call, *, db):
    return {
        "success": True,
        "tool": tool_call.name,
        "data": {
            "results": [
                {
                    "name": "Test Restaurant",
                    "city": "Pune",
                    "type": "restaurant",
                }
            ]
        },
    }


def no_tool_response():
    return SimpleNamespace(
        provider="groq",
        model="test-model",
        content="Here is your test travel plan.",
        tool_calls=[],
    )


def tool_response():
    return SimpleNamespace(
        provider="groq",
        model="test-model",
        content="",
        tool_calls=[
            SimpleNamespace(
                name="place_search",
                arguments={
                    "search": "restaurants in Pune",
                    "place_type": "restaurant",
                    "page": 1,
                    "size": 10,
                },
            )
        ],
    )


def final_response():
    return SimpleNamespace(
        provider="groq",
        model="test-model",
        content="I found a restaurant in Pune.",
        tool_calls=[],
    )


async def test_no_tool_call():
    print("\n" + "=" * 60)
    print("CASE 1 — NO TOOL CALL")
    print("=" * 60)

    gateway = FakeGateway()
    gateway.initial_response = no_tool_response()

    agent = TravelPlanningAgent(gateway=gateway)

    result = await agent.run("Create a simple Pune travel plan.")

    print("Success       :", result.success)
    print("Provider      :", result.metadata.get("provider"))
    print("Mode          :", result.metadata.get("mode"))
    print("Gateway calls :", gateway.generate_with_tools_calls)

    assert isinstance(result, AgentResponse)
    assert result.success is True
    assert result.agent == "travel_planning"
    assert result.metadata["provider"] == "groq"
    assert result.metadata["tools_used"] == []
    assert gateway.generate_with_tools_calls == 1
    assert gateway.continue_with_tool_results_calls == 0

    print("PASSED")


async def test_tool_call_and_continuation():
    print("\n" + "=" * 60)
    print("CASE 2 — TOOL CALL + CONTINUATION")
    print("=" * 60)

    gateway = FakeGateway()
    gateway.initial_response = tool_response()
    gateway.final_response = final_response()

    agent = TravelPlanningAgent(gateway=gateway)
    agent._tool_executor.execute = fake_tool_execute

    result = await agent.run("Find restaurants in Pune.")

    print("Success       :", result.success)
    print("Provider      :", result.metadata.get("provider"))
    print("Tools used    :", result.metadata.get("tools_used"))
    print("Gateway calls :", gateway.generate_with_tools_calls)
    print("Continuation  :", gateway.continue_with_tool_results_calls)

    assert isinstance(result, AgentResponse)
    assert result.success is True
    assert result.metadata["provider"] == "groq"
    assert result.metadata["tools_used"] == ["place_search"]
    assert gateway.generate_with_tools_calls == 1
    assert gateway.continue_with_tool_results_calls == 1
    assert result.data["tool_results"][0]["success"] is True

    print("PASSED")


async def test_gateway_blocked():
    print("\n" + "=" * 60)
    print("CASE 3 — GATEWAY BLOCKED")
    print("=" * 60)

    gateway = FakeGateway()
    gateway.blocked = True

    agent = TravelPlanningAgent(gateway=gateway)

    result = await agent.run("Create a travel plan for Mumbai.")

    print("Success       :", result.success)
    print("Mode          :", result.metadata.get("mode"))
    print("Provider      :", result.metadata.get("provider"))

    assert isinstance(result, AgentResponse)
    assert result.success is False
    assert result.metadata["mode"] == "blocked"
    assert result.metadata["tools_used"] == []
    assert gateway.generate_with_tools_calls == 1
    assert gateway.continue_with_tool_results_calls == 0

    print("PASSED")


async def test_blocked_during_continuation():
    print()
    print("=" * 60)
    print("CASE 4 — BLOCKED DURING TOOL CONTINUATION")
    print("=" * 60)

    gateway = FakeGateway()

    # ------------------------------------------------------
    # IMPORTANT:
    #
    # First Gateway request MUST be allowed.
    # It returns a tool call.
    #
    # Then the fake tool execution changes the Gateway
    # to blocked, simulating Admin disabling paid AI
    # before the continuation request.
    # ------------------------------------------------------

    gateway.initial_response = tool_response()
    gateway.final_response = final_response()

    agent = TravelPlanningAgent(
        gateway=gateway,
    )

    async def execute_then_block(
        tool_call,
        *,
        db,
    ):
        # Tool itself succeeds.
        result = await fake_tool_execute(
            tool_call,
            db=db,
        )

        # Simulate billing becoming blocked
        # after the tool has executed.
        gateway.blocked = True

        return result

    # Replace only the executor for this test.
    agent._tool_executor.execute = execute_then_block

    result = await agent.run(
        "Find restaurants in Pune."
    )

    print(
        "Success       :",
        result.success,
    )

    print(
        "Mode          :",
        result.metadata.get("mode"),
    )

    print(
        "Tools used    :",
        result.metadata.get("tools_used"),
    )

    print(
        "Continuation  :",
        gateway.continue_with_tool_results_calls,
    )

    # ------------------------------------------------------
    # EXPECTED:
    #
    # Initial request succeeds.
    # Tool executes.
    # Billing becomes blocked.
    # Continuation is attempted.
    # Continuation is blocked.
    # ------------------------------------------------------

    assert isinstance(
        result,
        AgentResponse,
    )

    assert result.success is False

    assert result.metadata["mode"] == "blocked"

    # In the current TravelPlanningAgent implementation,
    # the tool is not added to tools_used until the
    # continuation succeeds.
    assert result.metadata["tools_used"] == ["place_search"]

    assert (
        gateway.generate_with_tools_calls == 1
    )

    assert (
        gateway.continue_with_tool_results_calls == 1
    )

    # Tool execution itself succeeded before
    # continuation was blocked.
    assert result.data["tool_results"]

    print("PASSED")

async def main():
    print("=" * 60)
    print("TRAVEL PLANNING AGENT + AI GATEWAY INTEGRATION TEST")
    print("=" * 60)

    await test_no_tool_call()
    await test_tool_call_and_continuation()
    await test_gateway_blocked()
    await test_blocked_during_continuation()

    print("\n" + "=" * 60)
    print("TRAVEL PLANNING AGENT + AI GATEWAY INTEGRATION TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
