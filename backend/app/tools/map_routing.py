from __future__ import annotations

from typing import Any

from app.integrations.maps.osrm import OSRMClient
from app.tools.base import Tool


class MapRoutingTool(Tool):
    """
    AI tool for calculating routes between two locations.

    Uses the OSM-based OSRM routing service.
    """

    def __init__(
        self,
        *,
        client: OSRMClient | None = None,
    ) -> None:
        self._client = client or OSRMClient()

    @property
    def name(self) -> str:
        return "map_routing"

    @property
    def description(self) -> str:
        return (
            "Calculate driving distance, travel time and route "
            "between two geographic coordinates. Use this tool "
            "when the user asks for directions, distance, travel "
            "time, route planning or travel time between places."
        )

    async def execute(
        self,
        *,
        origin_latitude: float,
        origin_longitude: float,
        destination_latitude: float,
        destination_longitude: float,
        db: Any = None,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """
        Calculate a route using OSRM.
        """

        result = await self._client.route(
            origin_latitude=float(origin_latitude),
            origin_longitude=float(origin_longitude),
            destination_latitude=float(destination_latitude),
            destination_longitude=float(destination_longitude),
        )

        return result
