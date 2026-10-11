"""
Admin Place API routes.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.dependencies.admin import get_current_admin
from app.modules.auth.model import User

from app.modules.place.schema import PlaceCreate
from app.modules.place.schema import PlaceResponse
from app.modules.place.schema import PlaceUpdate
from app.modules.place.service import PlaceService


router = APIRouter()

service = PlaceService()


# ==========================================================
# Admin Place List
# ==========================================================

@router.get(
    "/",
    summary="Get all places for admin",
)
async def get_places(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """
    Return all non-deleted places for Admin.

    Admin can see both active and inactive places.
    """

    places = await service.get_all(
        db,
        active_only=False,
    )

    return {
        "success": True,
        "message": "Places retrieved successfully",
        "data": [
            PlaceResponse.model_validate(place)
            for place in places
        ],
    }


# ==========================================================
# Admin Place Details
# ==========================================================

@router.get(
    "/{place_id}",
    summary="Get place by ID for admin",
)
async def get_place(
    place_id: str,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """
    Get a place for Admin.

    Inactive places are allowed here.
    """

    place = await service.get_by_id(
        db,
        place_id,
        active_only=False,
    )

    return {
        "success": True,
        "message": "Place retrieved successfully",
        "data": PlaceResponse.model_validate(place),
    }


# ==========================================================
# Create
# ==========================================================

@router.post(
    "/",
    status_code=201,
    summary="Create place",
)
async def create_place(
    payload: PlaceCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """
    Create a new place.

    Only authenticated Admin users can create places.
    """

    place = await service.create(
        db,
        payload,
    )

    return {
        "success": True,
        "message": "Place created successfully",
        "data": PlaceResponse.model_validate(place),
    }


# ==========================================================
# Update
# ==========================================================

@router.patch(
    "/{place_id}",
    summary="Update place",
)
async def update_place(
    place_id: str,
    payload: PlaceUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """
    Update an existing place.

    Admin can also activate/deactivate a place.
    """

    place = await service.update(
        db,
        place_id,
        payload,
    )

    return {
        "success": True,
        "message": "Place updated successfully",
        "data": PlaceResponse.model_validate(place),
    }


# ==========================================================
# Delete
# ==========================================================

@router.delete(
    "/{place_id}",
    summary="Delete place",
)
async def delete_place(
    place_id: str,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """
    Soft-delete a place.

    The record remains in the database.
    """

    await service.delete(
        db,
        place_id,
    )

    return {
        "success": True,
        "message": "Place deleted successfully",
        "data": None,
    }