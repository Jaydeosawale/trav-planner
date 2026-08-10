"""
Seed lookup utilities.
"""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.city.model import City
from app.modules.country.model import Country
from app.modules.state.model import State


class LookupCache:
    """
    In-memory lookup cache for seeders.
    """

    # ==========================================================
    # Countries
    # ==========================================================

    @staticmethod
    async def countries(
        db: AsyncSession,
    ) -> dict[str, Country]:
        """
        Load countries into an in-memory lookup.

        Lookup key:
            country.iso2

        Example:
            {
                "IN": Country(...),
                "US": Country(...),
            }
        """

        result = await db.execute(
            select(Country)
        )

        return {
            country.iso2: country
            for country in result.scalars().all()
        }

    # ==========================================================
    # States
    # ==========================================================

    @staticmethod
    async def states(
        db: AsyncSession,
    ) -> dict[tuple[str, str], State]:
        """
        Load states into an in-memory lookup.

        Lookup key:
            (country_id, state.code)

        Example:
            {
                (country_id, "MH"): State(...),
                (country_id, "CA"): State(...),
            }

        State code is used instead of state name because
        state names are not guaranteed to be unique within
        a country.
        """

        result = await db.execute(
            select(State)
        )

        return {
            (state.country_id, state.code): state
            for state in result.scalars().all()
        }

    # ==========================================================
    # Cities
    # ==========================================================

    @staticmethod
    async def cities(
        db: AsyncSession,
    ) -> dict[tuple[str, str], City]:
        """
        Load cities into an in-memory lookup.

        Lookup key:
            (state_id, city.name)

        Example:
            {
                (state_id, "Mumbai"): City(...),
                (state_id, "Pune"): City(...),
            }
        """

        result = await db.execute(
            select(City)
        )

        return {
            (city.state_id, city.name): city
            for city in result.scalars().all()
        }