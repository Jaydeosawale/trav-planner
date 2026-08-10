"""
User repository.
"""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.model import User


class UserRepository:
    """
    Database operations for users.
    """

    async def get_by_id(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> User | None:
        result = await db.execute(
            select(User).where(
                User.id == user_id,
                User.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none()

    async def get_by_email(
        self,
        db: AsyncSession,
        email: str,
    ) -> User | None:
        result = await db.execute(
            select(User).where(
                User.email == email,
                User.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none()

    async def create(
        self,
        db: AsyncSession,
        user: User,
    ) -> User:
        db.add(user)

        await db.flush()
        await db.refresh(user)

        return user

    async def update(
        self,
        db: AsyncSession,
        user: User,
    ) -> User:
        await db.flush()
        await db.refresh(user)

        return user

    async def delete(
        self,
        db: AsyncSession,
        user: User,
    ) -> None:
        user.is_deleted = True

        await db.flush()