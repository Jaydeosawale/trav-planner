from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.country.model import Country
from app.repositories.base import BaseRepository


class CountryRepository(BaseRepository[Country]):
    """
    Country database operations.
    """

    def __init__(self) -> None:
        super().__init__(Country)

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[Country]:
        """
        Return all countries ordered by name.
        """

        result = await db.execute(
            select(Country)
            .where(
                Country.is_deleted.is_(False),
            )
            .order_by(
                Country.name,
            )
        )

        return list(result.scalars().all())

    async def get_active(
        self,
        db: AsyncSession,
    ) -> list[Country]:
        """
        Return active countries.
        """

        result = await db.execute(
            select(Country)
            .where(
                Country.is_deleted.is_(False),
                Country.is_active.is_(True),
            )
            .order_by(
                Country.name,
            )
        )

        return list(result.scalars().all())

    async def get_by_iso2(
        self,
        db: AsyncSession,
        iso2: str,
    ) -> Country | None:
        """
        Return country by ISO2 code.
        """

        result = await db.execute(
            select(Country).where(
                Country.iso2 == iso2.upper(),
                Country.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none()

    async def get_by_iso3(
        self,
        db: AsyncSession,
        iso3: str,
    ) -> Country | None:
        """
        Return country by ISO3 code.
        """

        result = await db.execute(
            select(Country).where(
                Country.iso3 == iso3.upper(),
                Country.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none()