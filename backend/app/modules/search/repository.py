"""
Search repository.

Search repository intentionally delegates domain-specific
retrieval to existing repositories.

This keeps Search as an orchestration layer rather than
duplicating database queries.
"""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.place.model import Place
from app.modules.place.repository import PlaceRepository


class SearchRepository:
    """
    Repository used by the unified search layer.
    """

    def __init__(self) -> None:
        self.place_repository = PlaceRepository()

    # ======================================================
    # Place Search
    # ======================================================

    async def search_places(
        self,
        db: AsyncSession,
        *,
        page: int = 1,
        size: int = 20,
        search: str | None = None,
        country_id: str | None = None,
        state_id: str | None = None,
        city_id: str | None = None,
        place_type: str | None = None,
        category_id: str | None = None,
    ) -> tuple[list[Place], int]:
        """
        Search places through the existing PlaceRepository.

        Search owns orchestration.
        PlaceRepository owns place database retrieval.
        """

        return await self.place_repository.search(
            db,
            page=page,
            size=size,
            search=search,
            country_id=country_id,
            state_id=state_id,
            city_id=city_id,
            place_type=place_type,
            category_id=category_id,
            active_only=True,
        )