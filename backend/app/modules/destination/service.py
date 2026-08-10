"""
Destination service.
"""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.common.constants.not_found import NotFoundException
from app.common.exceptions.conflict import ConflictException
from app.modules.destination.model import Destination
from app.modules.destination.repository import DestinationRepository
from app.modules.destination.schema import DestinationCreate
from app.modules.destination.schema import DestinationUpdate


class DestinationService:
    """
    Destination business logic.
    """

    def __init__(self) -> None:
        self.repository = DestinationRepository()

    # ==========================================================
    # Create
    # ==========================================================

    async def create(
        self,
        db: AsyncSession,
        payload: DestinationCreate,
    ) -> Destination:
        """
        Create a new destination.
        """

        existing_destination = await self.repository.get_by_slug(
            db,
            payload.slug,
        )

        if existing_destination is not None:
            raise ConflictException(
                "A destination with this slug already exists."
            )

        destination = Destination(
            city_id=payload.city_id,
            name=payload.name,
            slug=payload.slug,
            short_description=payload.short_description,
            description=payload.description,
            image_url=payload.image_url,
            latitude=payload.latitude,
            longitude=payload.longitude,
            is_featured=payload.is_featured,
        )

        destination = await self.repository.create(
            db,
            destination,
        )

        await db.commit()

        return destination

    # ==========================================================
    # Get All
    # ==========================================================

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[Destination]:
        """
        Return all active destinations.
        """

        return await self.repository.get_all(db)

    # ==========================================================
    # Get By ID
    # ==========================================================

    async def get_by_id(
        self,
        db: AsyncSession,
        destination_id: str,
    ) -> Destination:
        """
        Return a destination by ID.
        """

        destination = await self.repository.get_by_id(
            db,
            destination_id,
        )

        if destination is None:
            raise NotFoundException("Destination")

        return destination

    # ==========================================================
    # Get By Slug
    # ==========================================================

    async def get_by_slug(
        self,
        db: AsyncSession,
        slug: str,
    ) -> Destination:
        """
        Return a destination by slug.
        """

        destination = await self.repository.get_by_slug(
            db,
            slug,
        )

        if destination is None:
            raise NotFoundException("Destination")

        return destination

    # ==========================================================
    # Update
    # ==========================================================

    async def update(
        self,
        db: AsyncSession,
        destination_id: str,
        payload: DestinationUpdate,
    ) -> Destination:
        """
        Update a destination.
        """

        destination = await self.get_by_id(
            db,
            destination_id,
        )

        update_data = payload.model_dump(
            exclude_unset=True,
        )

        if "slug" in update_data:
            existing_destination = await self.repository.get_by_slug(
                db,
                update_data["slug"],
            )

            if (
                existing_destination is not None
                and existing_destination.id != destination.id
            ):
                raise ConflictException(
                    "A destination with this slug already exists."
                )

        for field, value in update_data.items():
            setattr(destination, field, value)

        destination = await self.repository.update(
            db,
            destination,
        )

        await db.commit()

        return destination

    # ==========================================================
    # Delete
    # ==========================================================

    async def delete(
        self,
        db: AsyncSession,
        destination_id: str,
    ) -> Destination:
        """
        Soft delete a destination.
        """

        destination = await self.get_by_id(
            db,
            destination_id,
        )

        destination = await self.repository.delete(
            db,
            destination,
        )

        await db.commit()

        return destination