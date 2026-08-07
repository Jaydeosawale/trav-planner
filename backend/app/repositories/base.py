"""
Generic SQLAlchemy Repository.

Every repository inherits from this class.
"""

from __future__ import annotations

from typing import Generic
from typing import TypeVar

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.base import Base

ModelType = TypeVar("ModelType", bound=Base)


class BaseRepository(Generic[ModelType]):
    """
    Generic repository.
    """

    def __init__(
        self,
        model: type[ModelType],
    ):
        self.model = model

    async def get_by_id(
        self,
        db: AsyncSession,
        object_id: str,
    ) -> ModelType | None:
        """
        Get object by ID.
        """

        result = await db.execute(
            select(self.model).where(
                self.model.id == object_id,
                self.model.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none()

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[ModelType]:
        """
        Get all active records.
        """

        result = await db.execute(
            select(self.model).where(
                self.model.is_deleted.is_(False),
            )
        )

        return list(result.scalars().all())

    async def create(
        self,
        db: AsyncSession,
        obj: ModelType,
    ) -> ModelType:
        """
        Insert record.
        """

        db.add(obj)

        await db.commit()

        await db.refresh(obj)

        return obj

    async def update(
        self,
        db: AsyncSession,
        obj: ModelType,
    ) -> ModelType:
        """
        Update record.
        """

        await db.commit()

        await db.refresh(obj)

        return obj

    async def delete(
        self,
        db: AsyncSession,
        obj: ModelType,
    ) -> None:
        """
        Soft delete.
        """

        obj.is_deleted = True

        await db.commit()