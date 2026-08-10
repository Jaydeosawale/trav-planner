"""
Destination module router.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import success_response
from app.database.session import get_db
from app.modules.destination.schema import DestinationCreate
from app.modules.destination.schema import DestinationResponse
from app.modules.destination.schema import DestinationUpdate
from app.modules.destination.service import DestinationService


router = APIRouter()

service = DestinationService()


# ==========================================================
# Create
# ==========================================================

@router.post(
    "/",
    summary="Create destination",
)
async def create_destination(
    payload: DestinationCreate,
    db: AsyncSession = Depends(get_db),
):
    """
    Create a new destination.
    """

    destination = await service.create(
        db,
        payload,
    )

    return success_response(
        data=DestinationResponse.model_validate(destination),
        message="Destination created successfully",
    )


# ==========================================================
# Get All
# ==========================================================

@router.get(
    "/",
    summary="Get destinations",
)
async def get_destinations(
    db: AsyncSession = Depends(get_db),
):
    """
    Return all active destinations.
    """

    destinations = await service.get_all(db)

    return success_response(
        data=[
            DestinationResponse.model_validate(
                destination,
            )
            for destination in destinations
        ],
        message="Destinations retrieved successfully",
    )


# ==========================================================
# Get By ID
# ==========================================================

@router.get(
    "/{destination_id}",
    summary="Get destination by ID",
)
async def get_destination(
    destination_id: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Return a destination by ID.
    """

    destination = await service.get_by_id(
        db,
        destination_id,
    )

    return success_response(
        data=DestinationResponse.model_validate(destination),
        message="Destination retrieved successfully",
    )


# ==========================================================
# Get By Slug
# ==========================================================

@router.get(
    "/slug/{slug}",
    summary="Get destination by slug",
)
async def get_destination_by_slug(
    slug: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Return a destination by slug.
    """

    destination = await service.get_by_slug(
        db,
        slug,
    )

    return success_response(
        data=DestinationResponse.model_validate(destination),
        message="Destination retrieved successfully",
    )


# ==========================================================
# Update
# ==========================================================

@router.patch(
    "/{destination_id}",
    summary="Update destination",
)
async def update_destination(
    destination_id: str,
    payload: DestinationUpdate,
    db: AsyncSession = Depends(get_db),
):
    """
    Update an existing destination.
    """

    destination = await service.update(
        db,
        destination_id,
        payload,
    )

    return success_response(
        data=DestinationResponse.model_validate(destination),
        message="Destination updated successfully",
    )


# ==========================================================
# Delete
# ==========================================================

@router.delete(
    "/{destination_id}",
    summary="Delete destination",
)
async def delete_destination(
    destination_id: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Soft delete a destination.
    """

    await service.delete(
        db,
        destination_id,
    )

    return success_response(
        data=None,
        message="Destination deleted successfully",
    )