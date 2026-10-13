from __future__ import annotations

from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.place.service import PlaceService
from app.tools.base import Tool


class PlaceSearchTool(Tool):
    """
    AI tool for discovering travel places from Trav Planner.

    Uses the existing PlaceService and PlaceRepository layers.
    """

    def __init__(self) -> None:
        self._service = PlaceService()

    @property
    def name(self) -> str:
        return "place_search"

    @property
    def description(self) -> str:
        return (
            "Search Trav Planner places such as restaurants, cafes, "
            "hotels, airports, railway stations, attractions, museums, "
            "parks, beaches and activities. "
            "Use this tool when the user asks to find or recommend places."
        )

    async def execute(
        self,
        *,
        db: AsyncSession,
        search: str | None = None,
        country_id: str | None = None,
        state_id: str | None = None,
        city_id: str | None = None,
        place_type: str | None = None,
        category_id: str | None = None,
        page: int = 1,
        size: int = 10,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """
        Search places using the existing PlaceService.
        """

        size = max(1, min(20, size)) if isinstance(size, int) else 10
        page = max(1, min(1000, page)) if isinstance(page, int) else 1
        places, total = await self._service.search(
            db=db,
            search=search,
            country_id=country_id,
            state_id=state_id,
            city_id=city_id,
            place_type=place_type,
            category_id=category_id,
            page=page,
            size=size,
        )

        # Add only already-cached source records; background discovery is
        # requested by the user in Explore, not an unbounded model tool loop.
        from app.services.discovery.world import DiscoveryCache, now, visible
        from sqlalchemy import select
        from app.modules.city.model import City
        import json

        selected_city = city_id
        if not selected_city and search:
            matches = (
                await db.scalars(
                    select(City)
                    .where(
                        City.name.ilike(search.strip()),
                        City.is_active.is_(True),
                        City.is_deleted.is_(False),
                    )
                    .limit(2)
                )
            ).all()
            if len(matches) == 1:
                selected_city = matches[0].id
        cached = []
        if selected_city:
            rows = (
                await db.scalars(
                    select(DiscoveryCache)
                    .where(
                        DiscoveryCache.city_id == selected_city,
                        DiscoveryCache.kind == "candidate",
                        DiscoveryCache.expires_at > now(),
                    )
                    .limit(100)
                )
            ).all()
            known = {str(place.id) for place in places}
            cached = await visible(
                db, [json.loads(row.value) for row in rows], selected_city
            )
            cached = [
                item
                for item in cached
                if item["id"] not in known
                and (not place_type or item["place_type"] == place_type)
            ][:20]
        result = {
            "items": [
                {
                    "id": str(place.id),
                    "name": place.name,
                    "place_type": place.place_type,
                    "short_description": place.short_description,
                    "description": place.description,
                    "visiting_notes": place.visiting_notes,
                    "address": place.address,
                    "locality": place.locality,
                    "latitude": (
                        float(place.latitude) if place.latitude is not None else None
                    ),
                    "longitude": (
                        float(place.longitude) if place.longitude is not None else None
                    ),
                    "image_url": place.image_url,
                    "rating": (
                        float(place.rating) if place.rating is not None else None
                    ),
                    "price_level": place.price_level,
                    "is_featured": place.is_featured,
                    "city": (place.city.name if place.city is not None else None),
                    "category": (
                        place.category.name if place.category is not None else None
                    ),
                }
                for place in places
            ],
            "total": total + len(cached),
            "page": page,
            "size": size,
        }

        allowance = max(0, min(size, 10) - len(places))
        for item in cached[:allowance]:
            compact = {
                key: item.get(key)
                for key in [
                    "id",
                    "name",
                    "city_id",
                    "place_type",
                    "latitude",
                    "longitude",
                    "provider",
                    "external_place_id",
                    "is_discovery",
                ]
            }
            compact["description"] = (item.get("description") or "")[:500]
            compact["visiting_notes"] = (item.get("visiting_notes") or "")[:400]
            result["items"].append(compact)
        result["source_note"] = (
            "Cached source data may be incomplete; hours, availability and prices are unverified."
        )
        return result
