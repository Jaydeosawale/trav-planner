"""
Destination repository.
"""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.destination.model import Destination


class DestinationRepository:
    """
    Database operations for destinations.
    """

    # ==========================================================
    # Get All
    # ==========================================================

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[Destination]:
        """
        Return all non-deleted destinations.

        The related city is eagerly loaded so async SQLAlchemy
        does not need a lazy database query later.
        """

        result = await db.execute(
            select(Destination)
            .options(
                selectinload(Destination.city),
            )
            .where(
                Destination.is_deleted.is_(False),
            )
            .order_by(
                Destination.name.asc(),
            )
        )

        return list(result.scalars().all())

    # ==========================================================
    # Get By ID
    # ==========================================================

    async def get_by_id(
        self,
        db: AsyncSession,
        destination_id: str,
    ) -> Destination | None:
        """
        Return a destination by ID.

        The related city is eagerly loaded.
        """

        result = await db.execute(
            select(Destination)
            .options(
                selectinload(Destination.city),
            )
            .where(
                Destination.id == destination_id,
                Destination.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none()

    # ==========================================================
    # Get By Slug
    # ==========================================================

    async def get_by_slug(
        self,
        db: AsyncSession,
        slug: str,
    ) -> Destination | None:
        """
        Return a destination by slug.

        The related city is eagerly loaded.
        """

        result = await db.execute(
            select(Destination)
            .options(
                selectinload(Destination.city),
            )
            .where(
                Destination.slug == slug,
                Destination.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none()

    # ==========================================================
    # Create
    # ==========================================================

    async def create(
        self,
        db: AsyncSession,
        destination: Destination,
    ) -> Destination:
        """
        Add a destination to the database.
        """

        db.add(destination)

        await db.commit()
        await db.refresh(destination)

        return destination

    # ==========================================================
    # Update
    # ==========================================================

    async def update(
        self,
        db: AsyncSession,
        destination: Destination,
    ) -> Destination:
        """
        Update a destination.
        """

        await db.commit()
        await db.refresh(destination)

        return destination

    # ==========================================================
    # Delete
    # ==========================================================

    async def delete(
        self,
        db: AsyncSession,
        destination: Destination,
    ) -> Destination:
        """
        Soft delete a destination.
        """

        destination.is_deleted = True

        await db.commit()

        return destination