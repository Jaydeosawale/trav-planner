from __future__ import annotations

from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.llm.base import LLMToolCall
from app.tools.registry import ToolRegistry


class ToolExecutor:
    """
    Executes tools requested by an AI agent.

    The executor keeps tool execution separate from:
        - the LLM provider
        - the agent
        - individual tools
    """

    def __init__(self, registry: ToolRegistry) -> None:
        self._registry = registry

    async def execute(
        self,
        tool_call: LLMToolCall,
        *,
        db: AsyncSession,
    ) -> dict[str, Any]:
        """
        Execute one normalized LLM tool call.
        """

        tool = self._registry.get(tool_call.name)

        arguments = dict(tool_call.arguments)

        result = await tool.execute(
            db=db,
            **arguments,
        )

        return {
            "tool_call_id": tool_call.id,
            "tool_name": tool_call.name,
            "result": result,
        }