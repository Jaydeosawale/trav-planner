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

    # ==========================================================
    # Get By ID
    # ==========================================================

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

    # ==========================================================
    # Get By Email
    # ==========================================================

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

    # ==========================================================
    # Create
    # ==========================================================

    async def create(
        self,
        db: AsyncSession,
        user: User,
    ) -> User:
        """
        Create a user.
        """

        db.add(user)

        await db.commit()
        await db.refresh(user)

        return user

    # ==========================================================
    # Update
    # ==========================================================

    async def update(
        self,
        db: AsyncSession,
        user: User,
    ) -> User:
        """
        Persist user changes.
        """

        await db.commit()
        await db.refresh(user)

        return user

    # ==========================================================
    # Delete
    # ==========================================================

    async def delete(
        self,
        db: AsyncSession,
        user: User,
    ) -> None:
        """
        Soft delete a user.
        """

        user.is_deleted = True

        await db.commit()