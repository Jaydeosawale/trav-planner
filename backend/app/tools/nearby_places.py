from app.tools.base import Tool
from app.services.discovery.nearby import NearbyRequest, search


class NearbyPlacesTool(Tool):
    @property
    def name(self):
        return "nearby_places"

    @property
    def description(self):
        return "Find stored places near a known place coordinate. Never guess a user location; ask for a city or use supplied verified coordinates."

    async def execute(
        self, *, db, latitude, longitude, radius_km=5, kind="all", **kwargs
    ):
        result = await search(
            db,
            NearbyRequest(
                latitude=latitude, longitude=longitude, radius_km=radius_km, kind=kind
            ),
            enrich=False,
        )
        result["items"] = [
            {
                k: p.get(k)
                for k in [
                    "id",
                    "name",
                    "city_id",
                    "place_type",
                    "latitude",
                    "longitude",
                    "distance_km",
                ]
            }
            for p in result["items"][:10]
        ]
        return result
