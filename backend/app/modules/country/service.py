"""
Country service.
"""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.country.model import Country
from app.modules.country.repository import CountryRepository
from app.modules.country.schema import CountryAdminUpdate
from app.services.base import BaseService


class CountryService(BaseService[Country]):
    """
    Country business logic.

    Countries are seeded master data.

    Public users primarily consume country information,
    while Admin can control whether a country is active.
    """

    def __init__(self) -> None:
        super().__init__(
            CountryRepository()
        )

    # ==========================================================
    # Get All
    # ==========================================================

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[Country]:
        """
        Return all non-deleted countries.

        Includes active and inactive countries.
        """

        return await self.repository.get_all(
            db
        )

    # ==========================================================
    # Get Active
    # ==========================================================

    async def get_active(
        self,
        db: AsyncSession,
    ) -> list[Country]:
        """
        Return active countries.
        """

        return await self.repository.get_active(
            db
        )

    # ==========================================================
    # Get By ISO2
    # ==========================================================

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

    # ==========================================================
    # Get By ISO3
    # ==========================================================

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

    # ==========================================================
    # Admin Update
    # ==========================================================

    async def admin_update(
        self,
        db: AsyncSession,
        country_id: str,
        payload: CountryAdminUpdate,
    ) -> Country | None:
        """
        Update Admin-controlled country settings.

        Currently this controls only is_active.
        """

        country = await self.repository.get_by_id(
            db,
            country_id,
        )

        if country is None:
            return None

        country.is_active = payload.is_active

        return await self.repository.update(
            db,
            country,
        )