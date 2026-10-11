"""
Destination Photo Service.
"""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.common.constants.not_found import NotFoundException
from app.modules.destination.repository import DestinationRepository
from app.modules.destination_photo.model import DestinationPhoto
from app.modules.destination_photo.repository import (
    DestinationPhotoRepository,
)
from app.modules.destination_photo.schema import (
    DestinationPhotoCreate,
    DestinationPhotoUpdate,
)


class DestinationPhotoService:
    """
    Business logic for destination photos.
    """

    def __init__(self) -> None:
        self.repository = DestinationPhotoRepository()
        self.destination_repository = DestinationRepository()

    # ==========================================================
    # Get Gallery
    # ==========================================================

    async def get_gallery(
        self,
        db: AsyncSession,
        destination_id: str,
    ) -> list[DestinationPhoto]:

        destination = await self.destination_repository.get_by_id(
            db,
            destination_id,
        )

        if destination is None:
            raise NotFoundException("Destination")

        return await self.repository.get_by_destination(
            db,
            destination_id,
        )

    # ==========================================================
    # Get Admin Gallery
    # ==========================================================

    async def get_admin_gallery(
        self,
        db: AsyncSession,
        destination_id: str,
    ) -> list[DestinationPhoto]:

        destination = await self.destination_repository.get_by_id(
            db,
            destination_id,
        )

        if destination is None:
            raise NotFoundException("Destination")

        return await self.repository.get_all_by_destination(
            db,
            destination_id,
        )

    # ==========================================================
    # Create
    # ==========================================================

    async def create(
        self,
        db: AsyncSession,
        destination_id: str,
        payload: DestinationPhotoCreate,
    ) -> DestinationPhoto:

        destination = await self.destination_repository.get_by_id(
            db,
            destination_id,
        )

        if destination is None:
            raise NotFoundException("Destination")

        if payload.is_cover:
            await self.repository.clear_covers(
                db,
                destination_id,
            )

        photo = DestinationPhoto(
            destination_id=destination_id,
            image_url=payload.image_url,
            caption=payload.caption,
            display_order=payload.display_order,
            is_cover=payload.is_cover,
            is_active=payload.is_active,
        )

        return await self.repository.create(
            db,
            photo,
        )

    # ==========================================================
    # Update
    # ==========================================================

    async def update(
        self,
        db: AsyncSession,
        photo_id: str,
        payload: DestinationPhotoUpdate,
    ) -> DestinationPhoto:

        photo = await self.repository.get_by_id(
            db,
            photo_id,
        )

        if photo is None:
            raise NotFoundException("Destination photo")

        if payload.is_cover is True:
            await self.repository.clear_covers(
                db,
                photo.destination_id,
            )

        if payload.image_url is not None:
            photo.image_url = payload.image_url

        if payload.caption is not None:
            photo.caption = payload.caption

        if payload.display_order is not None:
            photo.display_order = payload.display_order

        if payload.is_cover is not None:
            photo.is_cover = payload.is_cover

        if payload.is_active is not None:
            photo.is_active = payload.is_active

        return await self.repository.update(
            db,
            photo,
        )

    # ==========================================================
    # Delete
    # ==========================================================

    async def delete(
        self,
        db: AsyncSession,
        photo_id: str,
    ) -> bool:

        photo = await self.repository.get_by_id(
            db,
            photo_id,
        )

        if photo is None:
            raise NotFoundException("Destination photo")

        await self.repository.delete(
            db,
            photo,
        )

        return True