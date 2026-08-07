from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.state.model import State
from app.repositories.base import BaseRepository


class StateRepository(BaseRepository[State]):
    """
    State database operations.
    """

    def __init__(self) -> None:
        super().__init__(State)

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[State]:
        """
        Return all states.
        """

        result = await db.execute(
            select(State)
            .where(
                State.is_deleted.is_(False),
            )
            .order_by(
                State.name,
            )
        )

        return list(result.scalars().all())

    async def get_active(
        self,
        db: AsyncSession,
    ) -> list[State]:
        """
        Return active states.
        """

        result = await db.execute(
            select(State)
            .where(
                State.is_deleted.is_(False),
                State.is_active.is_(True),
            )
            .order_by(
                State.name,
            )
        )

        return list(result.scalars().all())

    async def get_by_country(
        self,
        db: AsyncSession,
        country_id: str,
    ) -> list[State]:
        """
        Return states for a country.
        """

        result = await db.execute(
            select(State)
            .where(
                State.country_id == country_id,
                State.is_deleted.is_(False),
            )
            .order_by(
                State.name,
            )
        )

        return list(result.scalars().all())

    async def get_by_code(
        self,
        db: AsyncSession,
        country_id: str,
        code: str,
    ) -> State | None:
        """
        Return state by code.
        """

        result = await db.execute(
            select(State).where(
                State.country_id == country_id,
                State.code == code.upper(),
                State.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none()

    async def exists_by_name(
        self,
        db: AsyncSession,
        country_id: str,
        name: str,
    ) -> bool:
        """
        Check whether a state already exists.
        """

        result = await db.execute(
            select(State.id).where(
                State.country_id == country_id,
                State.name == name,
                State.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none() is not None