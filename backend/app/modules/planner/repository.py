"""
Planner repository.
"""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.planner.model import Planner


class PlannerRepository:
    """
    Database operations for Planner.
    """

    # ==========================================================
    # Create
    # ==========================================================

    async def create(
        self,
        db: AsyncSession,
        planner: Planner,
    ) -> Planner:
        """
        Create a planner.
        """

        db.add(planner)

        await db.flush()

        await db.refresh(planner)

        return planner

    # ==========================================================
    # Get By ID
    # ==========================================================

    async def get_by_id(
        self,
        db: AsyncSession,
        planner_id: str,
    ) -> Planner | None:
        """
        Get a planner by ID.
        """

        result = await db.execute(
            select(Planner).where(
                Planner.id == planner_id,
                Planner.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none()

    # ==========================================================
    # Get By ID + User
    # ==========================================================

    async def get_by_id_for_user(
        self,
        db: AsyncSession,
        planner_id: str,
        user_id: str,
    ) -> Planner | None:
        """
        Get a planner belonging to a specific user.
        """

        result = await db.execute(
            select(Planner).where(
                Planner.id == planner_id,
                Planner.user_id == user_id,
                Planner.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none()

    # ==========================================================
    # Get All For User
    # ==========================================================

    async def get_all_for_user(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> list[Planner]:
        """
        Get all active planners belonging to a user.
        """

        result = await db.execute(
            select(Planner)
            .where(
                Planner.user_id == user_id,
                Planner.is_deleted.is_(False),
            )
            .order_by(Planner.created_at.desc())
        )

        return list(result.scalars().all())

    # ==========================================================
    # Update
    # ==========================================================

    async def update(
        self,
        db: AsyncSession,
        planner: Planner,
    ) -> Planner:
        """
        Persist planner changes.
        """

        await db.flush()

        await db.refresh(planner)

        return planner

    # ==========================================================
    # Soft Delete
    # ==========================================================

    async def soft_delete(
        self,
        db: AsyncSession,
        planner: Planner,
    ) -> None:
        """
        Soft delete a planner.
        """

        planner.is_deleted = True

        await db.flush()