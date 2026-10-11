from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any


class Tool(ABC):
    """
    Base abstraction for every Trav Planner AI tool.

    A tool is an executable capability that an AI agent can invoke.

    Examples:
        - PlaceSearchTool
        - WeatherTool
        - MapsTool
        - HotelSearchTool
        - BookingTool
        - PaymentTool
    """

    @property
    @abstractmethod
    def name(self) -> str:
        """
        Unique tool name exposed to the agent/LLM.
        """
        raise NotImplementedError

    @property
    @abstractmethod
    def description(self) -> str:
        """
        Description that helps the LLM understand when to use the tool.
        """
        raise NotImplementedError

    @abstractmethod
    async def execute(
        self,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """
        Execute the tool.

        Individual tools define their supported arguments.
        """
        raise NotImplementedError
