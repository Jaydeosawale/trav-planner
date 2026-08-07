"""
Generic Service Layer.

Provides reusable read operations for all modules.
"""

from __future__ import annotations

from typing import Generic
from typing import TypeVar

from sqlalchemy.ext.asyncio import AsyncSession

from app.database.base import Base
from app.repositories.base import BaseRepository

ModelType = TypeVar("ModelType", bound=Base)


class BaseService(Generic[ModelType]):
    """
    Base service for all modules.

    Contains only common read operations.

    Business logic such as create(), update(), delete()
    belongs inside each module service.
    """

    def __init__(
        self,
        repository: BaseRepository[ModelType],
    ) -> None:
        self.repository = repository

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[ModelType]:
        """
        Return all records.
        """

        return await self.repository.get_all(db)

    async def get_by_id(
        self,
        db: AsyncSession,
        object_id: str,
    ) -> ModelType | None:
        """
        Return object by ID.
        """

        return await self.repository.get_by_id(
            db,
            object_id,
        )

    async def exists(
        self,
        db: AsyncSession,
        object_id: str,
    ) -> bool:
        """
        Check whether a record exists.
        """

        return (
            await self.repository.get_by_id(
                db,
                object_id,
            )
            is not None
        )