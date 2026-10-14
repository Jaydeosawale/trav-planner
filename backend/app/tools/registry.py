from __future__ import annotations

from app.tools.nearby_places import NearbyPlacesTool
from app.tools.base import Tool
from app.tools.map_routing import MapRoutingTool
from app.tools.place_search import PlaceSearchTool


class ToolRegistry:
    """
    Central registry for Trav Planner AI tools.

    The registry keeps tool discovery separate from individual agents
    and LLM providers.
    """

    def __init__(self) -> None:
        self._tools: dict[str, Tool] = {}

    def register(self, tool: Tool) -> None:
        """
        Register a tool by its unique name.
        """

        if tool.name in self._tools:
            raise ValueError(f"Tool '{tool.name}' is already registered.")

        self._tools[tool.name] = tool

    def get(self, name: str) -> Tool:
        """
        Get a registered tool by name.
        """

        try:
            return self._tools[name]
        except KeyError as exc:
            raise KeyError(f"Tool '{name}' is not registered.") from exc

    def has(self, name: str) -> bool:
        """Return whether a tool is registered."""

        return name in self._tools

    def all(self) -> list[Tool]:
        """Return all registered tools."""

        return list(self._tools.values())

    def names(self) -> list[str]:
        """Return registered tool names."""

        return list(self._tools.keys())


def create_default_tool_registry() -> ToolRegistry:
    """
    Create the default Trav Planner tool registry.
    """

    registry = ToolRegistry()

    registry.register(PlaceSearchTool())

    registry.register(MapRoutingTool())

    registry.register(NearbyPlacesTool())
    return registry
