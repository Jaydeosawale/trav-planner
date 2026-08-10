from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.common.exceptions.conflict import ConflictException
from app.common.constants.not_found import NotFoundException
from app.modules.country.repository import CountryRepository

from app.modules.state.model import State
from app.modules.state.repository import StateRepository
from app.modules.state.schema import StateBase

from app.services.base import BaseService


class StateService(BaseService[State]):
    """
    State business logic.
    """

    def __init__(self) -> None:
        super().__init__(StateRepository())

        self.country_repository = CountryRepository()

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[State]:
        return await self.repository.get_all(db)

    async def get_active(
        self,
        db: AsyncSession,
    ) -> list[State]:
        return await self.repository.get_active(db)

    async def get_by_country(
        self,
        db: AsyncSession,
        country_id: str,
    ) -> list[State]:
        return await self.repository.get_by_country(
            db,
            country_id,
        )

    async def create(
        self,
        db: AsyncSession,
        payload: StateBase,
    ) -> State:
        """
        Create state.
        """

        country = await self.country_repository.get_by_id(
            db,
            payload.country_id,
        )

        if country is None:
            raise NotFoundException(
                "Country",
            )

        if await self.repository.exists_by_name(
            db,
            payload.country_id,
            payload.name,
        ):
            raise ConflictException(
                "State already exists.",
            )

        state = State(
            **payload.model_dump(),
            code=payload.code.upper(),
        )

        return await self.repository.create(
            db,
            state,
        )

    async def update(
        self,
        db: AsyncSession,
        state_id: str,
        payload: StateBase,
    ) -> State:
        """
        Update state.
        """

        state = await self.repository.get_by_id(
            db,
            state_id,
        )

        if state is None:
            raise NotFoundException(
                "State",
            )

        country = await self.country_repository.get_by_id(
            db,
            payload.country_id,
        )

        if country is None:
            raise NotFoundException(
                "Country",
            )

        state.country_id = payload.country_id
        state.name = payload.name
        state.code = payload.code.upper()
        state.is_active = payload.is_active

        return await self.repository.update(
            db,
            state,
        )

    async def delete(
        self,
        db: AsyncSession,
        state_id: str,
    ) -> bool:
        """
        Soft delete state.
        """

        state = await self.repository.get_by_id(
            db,
            state_id,
        )

        if state is None:
            raise NotFoundException(
                "State",
            )

        await self.repository.delete(
            db,
            state,
        )

        return True