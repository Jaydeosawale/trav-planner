from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any


@dataclass
class AgentContext:
    """
    Shared context available to an AI agent during execution.
    """

    user_id: str | None = None
    session_id: str | None = None

    # Data accumulated during the agent workflow.
    data: dict[str, Any] = field(default_factory=dict)

    # Conversation/history information.
    messages: list[dict[str, str]] = field(default_factory=list)


@dataclass
class AgentResponse:
    """
    Standard response returned by every agent.
    """

    content: str

    agent: str

    success: bool = True

    data: dict[str, Any] = field(default_factory=dict)

    metadata: dict[str, Any] = field(default_factory=dict)


class Agent(ABC):
    """
    Base abstraction for every Trav Planner AI agent.

    Agent = reasoning/decision-making component.

    Tools are capabilities that agents can invoke.
    """

    @property
    @abstractmethod
    def name(self) -> str:
        """Unique agent name."""
        raise NotImplementedError

    @property
    @abstractmethod
    def description(self) -> str:
        """Description of the agent's responsibility."""
        raise NotImplementedError

    @property
    def system_prompt(self) -> str:
        """
        Default system prompt for the agent.
        """
        return (
            f"You are the {self.name} agent for Trav Planner.\n"
            f"Your responsibility is: {self.description}"
        )

    @abstractmethod
    async def run(
        self,
        request: str,
        *,
        context: AgentContext | None = None,
        **kwargs: Any,
    ) -> AgentResponse:
        """
        Execute the agent.
        """
        raise NotImplementedError