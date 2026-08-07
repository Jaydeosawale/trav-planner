from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.common.exceptions.conflict import ConflictException
from app.common.exceptions.not_found import NotFoundException

from app.modules.city.model import City
from app.modules.city.repository import CityRepository
from app.modules.city.schema import CityBase

from app.modules.country.repository import CountryRepository
from app.modules.state.repository import StateRepository

from app.services.base import BaseService


class CityService(BaseService[City]):
    """
    City business logic.
    """

    def __init__(self) -> None:
        super().__init__(CityRepository())

        self.country_repository = CountryRepository()
        self.state_repository = StateRepository()

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[City]:
        return await self.repository.get_all(db)

    async def get_active(
        self,
        db: AsyncSession,
    ) -> list[City]:
        return await self.repository.get_active(db)

    async def get_by_country(
        self,
        db: AsyncSession,
        country_id: str,
    ) -> list[City]:
        return await self.repository.get_by_country(
            db,
            country_id,
        )

    async def get_by_state(
        self,
        db: AsyncSession,
        state_id: str,
    ) -> list[City]:
        return await self.repository.get_by_state(
            db,
            state_id,
        )

    async def create(
        self,
        db: AsyncSession,
        payload: CityBase,
    ) -> City:
        """
        Create city.
        """

        country = await self.country_repository.get_by_id(
            db,
            payload.country_id,
        )

        if country is None:
            raise NotFoundException(
                "Country",
            )

        state = await self.state_repository.get_by_id(
            db,
            payload.state_id,
        )

        if state is None:
            raise NotFoundException(
                "State",
            )

        if state.country_id != payload.country_id:
            raise ConflictException(
                "State does not belong to the selected country.",
            )

        if await self.repository.exists_by_name(
            db,
            payload.state_id,
            payload.name,
        ):
            raise ConflictException(
                "City already exists.",
            )

        city = City(
            **payload.model_dump(),
        )

        return await self.repository.create(
            db,
            city,
        )

    async def update(
        self,
        db: AsyncSession,
        city_id: str,
        payload: CityBase,
    ) -> City:
        """
        Update city.
        """

        city = await self.repository.get_by_id(
            db,
            city_id,
        )

        if city is None:
            raise NotFoundException(
                "City",
            )

        country = await self.country_repository.get_by_id(
            db,
            payload.country_id,
        )

        if country is None:
            raise NotFoundException(
                "Country",
            )

        state = await self.state_repository.get_by_id(
            db,
            payload.state_id,
        )

        if state is None:
            raise NotFoundException(
                "State",
            )

        if state.country_id != payload.country_id:
            raise ConflictException(
                "State does not belong to the selected country.",
            )

        city.country_id = payload.country_id
        city.state_id = payload.state_id
        city.name = payload.name
        city.latitude = payload.latitude
        city.longitude = payload.longitude
        city.is_active = payload.is_active

        return await self.repository.update(
            db,
            city,
        )

    async def delete(
        self,
        db: AsyncSession,
        city_id: str,
    ) -> bool:
        """
        Soft delete city.
        """

        city = await self.repository.get_by_id(
            db,
            city_id,
        )

        if city is None:
            raise NotFoundException(
                "City",
            )

        await self.repository.delete(
            db,
            city,
        )

        return True