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

        return {
            "items": [
                {
                    "id": str(place.id),
                    "name": place.name,
                    "place_type": place.place_type,
                    "short_description": place.short_description,
                    "description": place.description,
                    "address": place.address,
                    "locality": place.locality,
                    "latitude": (
                        float(place.latitude)
                        if place.latitude is not None
                        else None
                    ),
                    "longitude": (
                        float(place.longitude)
                        if place.longitude is not None
                        else None
                    ),
                    "image_url": place.image_url,
                    "rating": (
                        float(place.rating)
                        if place.rating is not None
                        else None
                    ),
                    "price_level": place.price_level,
                    "is_featured": place.is_featured,
                    "city": (
                        place.city.name
                        if place.city is not None
                        else None
                    ),
                    "category": (
                        place.category.name
                        if place.category is not None
                        else None
                    ),
                }
                for place in places
            ],
            "total": total,
            "page": page,
            "size": size,
        }
