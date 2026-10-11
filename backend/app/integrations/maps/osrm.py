from __future__ import annotations

from typing import Any

import httpx


class OSRMClient:
    """
    Small async client for the OSRM routing API.

    OSRM uses coordinates in:
        longitude,latitude

    while our application generally works with:
        latitude,longitude
    """

    def __init__(
        self,
        *,
        base_url: str = "https://router.project-osrm.org",
        timeout: float = 15.0,
    ) -> None:
        self._base_url = base_url.rstrip("/")
        self._timeout = timeout

    async def route(
        self,
        *,
        origin_latitude: float,
        origin_longitude: float,
        destination_latitude: float,
        destination_longitude: float,
        alternatives: bool = False,
        steps: bool = True,
        geometries: str = "geojson",
        overview: str = "full",
    ) -> dict[str, Any]:
        """
        Calculate a driving route between two coordinates.

        Returns normalized route information.
        """

        coordinates = (
            f"{origin_longitude},{origin_latitude};"
            f"{destination_longitude},{destination_latitude}"
        )

        url = (
            f"{self._base_url}/route/v1/driving/"
            f"{coordinates}"
        )

        params = {
            "alternatives": str(alternatives).lower(),
            "steps": str(steps).lower(),
            "geometries": geometries,
            "overview": overview,
        }

        async with httpx.AsyncClient(
            timeout=self._timeout
        ) as client:

            response = await client.get(
                url,
                params=params,
                headers={
                    "User-Agent": "TravPlanner/1.0",
                },
            )

            response.raise_for_status()

            data = response.json()

        if data.get("code") != "Ok":
            raise RuntimeError(
                f"OSRM routing failed: "
                f"{data.get('code', 'Unknown error')}"
            )

        routes = data.get("routes") or []

        if not routes:
            raise RuntimeError(
                "OSRM returned no route."
            )

        route = routes[0]

        return {
            "provider": "osrm",
            "profile": "driving",
            "distance_meters": route.get(
                "distance",
                0,
            ),
            "duration_seconds": route.get(
                "duration",
                0,
            ),
            "distance_km": round(
                route.get("distance", 0) / 1000,
                2,
            ),
            "duration_minutes": round(
                route.get("duration", 0) / 60,
                1,
            ),
            "geometry": route.get(
                "geometry"
            ),
            "legs": route.get(
                "legs",
                [],
            ),
            "waypoints": data.get(
                "waypoints",
                [],
            ),
            "alternatives": data.get(
                "routes",
                [])[1:],
        }