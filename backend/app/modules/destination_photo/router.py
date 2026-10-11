"""
Destination Photo API Router.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import (
    ApiResponse,
    success_response,
)
from app.database.session import get_db
from app.modules.destination_photo.schema import (
    DestinationPhotoCreate,
    DestinationPhotoResponse,
    DestinationPhotoUpdate,
)
from app.modules.destination_photo.service import (
    DestinationPhotoService,
)


router = APIRouter()

service = DestinationPhotoService()


# ==========================================================
# Get Public Gallery
# ==========================================================


@router.get(
    "/destination/{destination_id}",
    response_model=ApiResponse[
        list[DestinationPhotoResponse]
    ],
)
async def get_destination_photos(
    destination_id: str,
    db: AsyncSession = Depends(get_db),
):

    photos = await service.get_gallery(
        db,
        destination_id,
    )

    return success_response(
        data=photos,
        message="Destination photos fetched successfully.",
    )


# ==========================================================
# Get Admin Gallery
# ==========================================================


@router.get(
    "/destination/{destination_id}/admin",
    response_model=ApiResponse[
        list[DestinationPhotoResponse]
    ],
)
async def get_admin_destination_photos(
    destination_id: str,
    db: AsyncSession = Depends(get_db),
):

    photos = await service.get_admin_gallery(
        db,
        destination_id,
    )

    return success_response(
        data=photos,
        message="Destination photos fetched successfully.",
    )


# ==========================================================
# Create Photo
# ==========================================================


@router.post(
    "/destination/{destination_id}",
    response_model=ApiResponse[
        DestinationPhotoResponse
    ],
)
async def create_destination_photo(
    destination_id: str,
    payload: DestinationPhotoCreate,
    db: AsyncSession = Depends(get_db),
):

    photo = await service.create(
        db,
        destination_id,
        payload,
    )

    return success_response(
        data=photo,
        message="Destination photo added successfully.",
    )


# ==========================================================
# Update Photo
# ==========================================================


@router.patch(
    "/{photo_id}",
    response_model=ApiResponse[
        DestinationPhotoResponse
    ],
)
async def update_destination_photo(
    photo_id: str,
    payload: DestinationPhotoUpdate,
    db: AsyncSession = Depends(get_db),
):

    photo = await service.update(
        db,
        photo_id,
        payload,
    )

    return success_response(
        data=photo,
        message="Destination photo updated successfully.",
    )


# ==========================================================
# Delete Photo
# ==========================================================


@router.delete(
    "/{photo_id}",
    response_model=ApiResponse[None],
)
async def delete_destination_photo(
    photo_id: str,
    db: AsyncSession = Depends(get_db),
):

    await service.delete(
        db,
        photo_id,
    )

    return success_response(
        message="Destination photo deleted successfully.",
    )