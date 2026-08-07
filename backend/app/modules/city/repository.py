from __future__ import annotations

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

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[City]:
        """
        Return all cities.
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

    async def get_active(
        self,
        db: AsyncSession,
    ) -> list[City]:
        """
        Return active cities.
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

        return result.scalar_one_or_none() is not None