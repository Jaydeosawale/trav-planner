"""
City Repository.
"""

from __future__ import annotations

from sqlalchemy import func
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.city.model import City
from app.repositories.base import BaseRepository


class CityRepository(BaseRepository[City]):
    """
    City database operations.
    """

    def __init__(self) -> None:
        super().__init__(City)

    # ==========================================================
    # Get All Cities
    # ==========================================================

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[City]:
        """
        Return all cities.

        Kept for existing API compatibility.
        Prefer search() for Admin/AI use.
        """

        result = await db.execute(
            select(City)
            .where(
                City.is_deleted.is_(False),
            )
            .order_by(
                City.name,
            )
        )

        return list(result.scalars().all())

    # ==========================================================
    # Get Active Cities
    # ==========================================================

    async def get_active(
        self,
        db: AsyncSession,
    ) -> list[City]:
        """
        Return active cities.

        Kept for existing API compatibility.
        """

        result = await db.execute(
            select(City)
            .where(
                City.is_deleted.is_(False),
                City.is_active.is_(True),
            )
            .order_by(
                City.name,
            )
        )

        return list(result.scalars().all())

    # ==========================================================
    # Get Cities By Country
    # ==========================================================

    async def get_by_country(
        self,
        db: AsyncSession,
        country_id: str,
    ) -> list[City]:
        """
        Return cities belonging to a country.
        """

        result = await db.execute(
            select(City)
            .where(
                City.country_id == country_id,
                City.is_deleted.is_(False),
            )
            .order_by(
                City.name,
            )
        )

        return list(result.scalars().all())

    # ==========================================================
    # Get Cities By State
    # ==========================================================

    async def get_by_state(
        self,
        db: AsyncSession,
        state_id: str,
    ) -> list[City]:
        """
        Return cities belonging to a state.
        """

        result = await db.execute(
            select(City)
            .where(
                City.state_id == state_id,
                City.is_deleted.is_(False),
            )
            .order_by(
                City.name,
            )
        )

        return list(result.scalars().all())

    # ==========================================================
    # Search / Pagination
    # ==========================================================

    async def search(
        self,
        db: AsyncSession,
        *,
        page: int = 1,
        size: int = 50,
        search: str | None = None,
        country_id: str | None = None,
        state_id: str | None = None,
    ) -> tuple[list[City], int]:
        """
        Search and paginate cities.

        Designed for:
        - Admin CMS
        - Search UI
        - Future AI retrieval
        """

        filters = [
            City.is_deleted.is_(False),
            City.is_active.is_(True),
        ]

        # ------------------------------------------------------
        # Name Search
        # ------------------------------------------------------

        if search:
            search_value = search.strip()

            if search_value:
                filters.append(
                    City.name.ilike(
                        f"%{search_value}%"
                    )
                )

        # ------------------------------------------------------
        # Country Filter
        # ------------------------------------------------------

        if country_id:
            filters.append(
                City.country_id == country_id,
            )

        # ------------------------------------------------------
        # State Filter
        # ------------------------------------------------------

        if state_id:
            filters.append(
                City.state_id == state_id,
            )

        # ------------------------------------------------------
        # Total Count
        # ------------------------------------------------------

        count_result = await db.execute(
            select(func.count())
            .select_from(City)
            .where(*filters)
        )

        total = count_result.scalar_one()

        # ------------------------------------------------------
        # Pagination
        # ------------------------------------------------------

        offset = (page - 1) * size

        result = await db.execute(
            select(City)
            .where(*filters)
            .order_by(
                City.name,
            )
            .offset(offset)
            .limit(size)
        )

        cities = list(
            result.scalars().all()
        )

        return cities, total

    # ==========================================================
    # Exists By Name
    # ==========================================================

    async def exists_by_name(
        self,
        db: AsyncSession,
        state_id: str,
        name: str,
    ) -> bool:
        """
        Check whether a city already exists
        within a state.
        """

        result = await db.execute(
            select(City.id).where(
                City.state_id == state_id,
                City.name == name,
                City.is_deleted.is_(False),
            )
        )

        return (
            result.scalar_one_or_none()
            is not None
        )