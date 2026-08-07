from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.country.model import Country
from app.modules.country.repository import CountryRepository
from app.services.base import BaseService


class CountryService(BaseService[Country]):
    """
    Country business logic.

    Countries are master data and are seeded into
    the database. Therefore, this service primarily
    exposes read operations.
    """

    def __init__(self) -> None:
        super().__init__(CountryRepository())

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[Country]:
        """
        Return all countries.
        """

        return await self.repository.get_all(db)

    async def get_active(
        self,
        db: AsyncSession,
    ) -> list[Country]:
        """
        Return active countries.
        """

        return await self.repository.get_active(db)

    async def get_by_iso2(
        self,
        db: AsyncSession,
        iso2: str,
    ) -> Country | None:
        """
        Return country by ISO2 code.
        """

        return await self.repository.get_by_iso2(
            db,
            iso2,
        )

    async def get_by_iso3(
        self,
        db: AsyncSession,
        iso3: str,
    ) -> Country | None:
        """
        Return country by ISO3 code.
        """

        return await self.repository.get_by_iso3(
            db,
            iso3,
        )