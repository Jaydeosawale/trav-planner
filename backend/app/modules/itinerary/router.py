"""
Itinerary API routes.

User ownership is enforced by ItineraryService.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import success_response
from app.database.session import get_db
from app.dependencies.current_user import get_current_user
from app.modules.auth.model import User
from app.modules.itinerary.schema import (
    ItineraryDayCreate,
    ItineraryDayResponse,
    ItineraryDayUpdate,
    ItineraryItemCreate,
    ItineraryItemResponse,
    ItineraryItemUpdate,
    ItineraryResponse,
)
from app.modules.itinerary.service import ItineraryService


router = APIRouter()

service = ItineraryService()


# ==========================================================
# Complete Itinerary
# ==========================================================

@router.get(
    "/trips/{trip_id}",
    summary="Get complete trip itinerary",
)
async def get_itinerary(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get all itinerary days and items for a trip.
    """

    days = await service.get_itinerary(
        db,
        trip_id,
        current_user.id,
    )

    return success_response(
        data=ItineraryResponse(
            trip_id=trip_id,
            days=[
                ItineraryDayResponse.model_validate(
                    day,
                )
                for day in days
            ],
        ),
        message="Itinerary retrieved successfully",
    )


# ==========================================================
# Create Day
# ==========================================================

@router.post(
    "/trips/{trip_id}/days",
    summary="Create itinerary day",
)
async def create_day(
    trip_id: str,
    payload: ItineraryDayCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Create a day inside a user's trip.
    """

    day = await service.create_day(
        db,
        trip_id,
        current_user.id,
        payload,
    )

    return success_response(
        data=ItineraryDayResponse.model_validate(
            day,
        ),
        message="Itinerary day created successfully",
    )


# ==========================================================
# Update Day
# ==========================================================

@router.put(
    "/days/{day_id}",
    summary="Update itinerary day",
)
async def update_day(
    day_id: str,
    payload: ItineraryDayUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Update an itinerary day.
    """

    day = await service.update_day(
        db,
        day_id,
        current_user.id,
        payload,
    )

    return success_response(
        data=ItineraryDayResponse.model_validate(
            day,
        ),
        message="Itinerary day updated successfully",
    )


# ==========================================================
# Delete Day
# ==========================================================

@router.delete(
    "/days/{day_id}",
    summary="Delete itinerary day",
)
async def delete_day(
    day_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Delete an itinerary day and its items.
    """

    await service.delete_day(
        db,
        day_id,
        current_user.id,
    )

    return success_response(
        message="Itinerary day deleted successfully",
    )


# ==========================================================
# Create Item
# ==========================================================

@router.post(
    "/days/{day_id}/items",
    summary="Create itinerary item",
)
async def create_item(
    day_id: str,
    payload: ItineraryItemCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Create an activity/place/travel item inside a day.
    """

    item = await service.create_item(
        db,
        day_id,
        current_user.id,
        payload,
    )

    return success_response(
        data=ItineraryItemResponse.model_validate(
            item,
        ),
        message="Itinerary item created successfully",
    )


# ==========================================================
# Update Item
# ==========================================================

@router.put(
    "/items/{item_id}",
    summary="Update itinerary item",
)
async def update_item(
    item_id: str,
    payload: ItineraryItemUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Update an itinerary item.
    """

    item = await service.update_item(
        db,
        item_id,
        current_user.id,
        payload,
    )

    return success_response(
        data=ItineraryItemResponse.model_validate(
            item,
        ),
        message="Itinerary item updated successfully",
    )


# ==========================================================
# Delete Item
# ==========================================================

@router.delete(
    "/items/{item_id}",
    summary="Delete itinerary item",
)
async def delete_item(
    item_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Delete an itinerary item.
    """

    await service.delete_item(
        db,
        item_id,
        current_user.id,
    )

    return success_response(
        message="Itinerary item deleted successfully",
    )
