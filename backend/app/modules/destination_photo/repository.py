"""
Destination Photo Repository.
"""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.destination_photo.model import DestinationPhoto
from app.repositories.base import BaseRepository


class DestinationPhotoRepository(
    BaseRepository[DestinationPhoto],
):
    """
    Database operations for destination photos.
    """

    def __init__(self) -> None:
        super().__init__(DestinationPhoto)

    # ==========================================================
    # Get Photos
    # ==========================================================

    async def get_by_destination(
        self,
        db: AsyncSession,
        destination_id: str,
    ) -> list[DestinationPhoto]:

        result = await db.execute(
            select(DestinationPhoto)
            .where(
                DestinationPhoto.destination_id
                == destination_id,
                DestinationPhoto.is_deleted.is_(False),
                DestinationPhoto.is_active.is_(True),
            )
            .order_by(
                DestinationPhoto.display_order,
                DestinationPhoto.created_at,
            )
        )

        return list(result.scalars().all())

    # ==========================================================
    # Get Cover
    # ==========================================================

    async def get_cover(
        self,
        db: AsyncSession,
        destination_id: str,
    ) -> DestinationPhoto | None:

        result = await db.execute(
            select(DestinationPhoto)
            .where(
                DestinationPhoto.destination_id
                == destination_id,
                DestinationPhoto.is_deleted.is_(False),
                DestinationPhoto.is_active.is_(True),
                DestinationPhoto.is_cover.is_(True),
            )
            .order_by(
                DestinationPhoto.display_order,
            )
        )

        return result.scalars().first()

    # ==========================================================
    # Get All Admin Photos
    # ==========================================================

    async def get_all_by_destination(
        self,
        db: AsyncSession,
        destination_id: str,
    ) -> list[DestinationPhoto]:

        result = await db.execute(
            select(DestinationPhoto)
            .where(
                DestinationPhoto.destination_id
                == destination_id,
                DestinationPhoto.is_deleted.is_(False),
            )
            .order_by(
                DestinationPhoto.display_order,
                DestinationPhoto.created_at,
            )
        )

        return list(result.scalars().all())

    # ==========================================================
    # Clear Cover
    # ==========================================================

    async def clear_covers(
        self,
        db: AsyncSession,
        destination_id: str,
    ) -> None:

        result = await db.execute(
            select(DestinationPhoto)
            .where(
                DestinationPhoto.destination_id
                == destination_id,
                DestinationPhoto.is_deleted.is_(False),
                DestinationPhoto.is_cover.is_(True),
            )
        )

        photos = result.scalars().all()

        for photo in photos:
            photo.is_cover = False