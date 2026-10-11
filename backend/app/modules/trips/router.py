"""
User Trip API routes.

Trips represent saved/planned travel journeys owned by
the authenticated user.

Planner = planning workspace/request.
Trip = actual saved travel journey/history.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from fastapi import Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import success_response
from app.database.session import get_db
from app.dependencies.current_user import get_current_user
from app.modules.auth.model import User
from app.modules.trips.schema import TripCreate
from app.modules.trips.schema import TripListResponse
from app.modules.trips.schema import TripPaginatedResponse
from app.modules.trips.schema import TripResponse
from app.modules.trips.schema import TripUpdate
from app.modules.trips.service import TripService


router = APIRouter()

service = TripService()


# ==========================================================
# Create Trip
# ==========================================================

@router.post(
    "/",
    summary="Create a trip",
)
async def create_trip(
    payload: TripCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Create a trip for the authenticated user.
    """

    trip = await service.create(
        db,
        current_user.id,
        payload,
    )

    return success_response(
        data=TripResponse.model_validate(trip),
        message="Trip created successfully",
    )


# ==========================================================
# Get Trips
# ==========================================================

@router.get(
    "/",
    summary="Get user trips",
)
async def get_trips(
    page: int = Query(
        default=1,
        ge=1,
    ),
    size: int = Query(
        default=20,
        ge=1,
        le=100,
    ),
    status: str | None = Query(
        default=None,
        min_length=1,
        max_length=50,
    ),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get trips belonging to the authenticated user.
    """

    trips, total = await service.get_trips(
        db,
        current_user.id,
        page=page,
        size=size,
        status=status,
    )

    pages = (
        (total + size - 1) // size
        if total > 0
        else 0
    )

    data = TripPaginatedResponse(
        items=[
            TripListResponse.model_validate(
                trip,
            )
            for trip in trips
        ],
        total=total,
        page=page,
        size=size,
        pages=pages,
    )

    return success_response(
        data=data,
        message="Trips retrieved successfully",
    )


# ==========================================================
# Upcoming Trips
# IMPORTANT:
# Must be before /{trip_id}
# ==========================================================

@router.get(
    "/upcoming",
    summary="Get upcoming trips",
)
async def get_upcoming_trips(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get the authenticated user's upcoming trips.
    """

    trips = await service.get_upcoming(
        db,
        current_user.id,
    )

    return success_response(
        data=[
            TripListResponse.model_validate(
                trip,
            )
            for trip in trips
        ],
        message="Upcoming trips retrieved successfully",
    )


# ==========================================================
# Past Trips
# IMPORTANT:
# Must be before /{trip_id}
# ==========================================================

@router.get(
    "/past",
    summary="Get past trips",
)
async def get_past_trips(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get the authenticated user's past trips.

    Past trips become an important personalization signal
    for the future recommendation and AI planning system.
    """

    trips = await service.get_past(
        db,
        current_user.id,
    )

    return success_response(
        data=[
            TripListResponse.model_validate(
                trip,
            )
            for trip in trips
        ],
        message="Past trips retrieved successfully",
    )


# ==========================================================
# Get Trip By ID
# IMPORTANT:
# Keep this after /upcoming and /past
# ==========================================================

@router.get(
    "/{trip_id}",
    summary="Get trip by ID",
)
async def get_trip(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get one trip owned by the authenticated user.
    """

    trip = await service.get_by_id(
        db,
        current_user.id,
        trip_id,
    )

    return success_response(
        data=TripResponse.model_validate(trip),
        message="Trip retrieved successfully",
    )


# ==========================================================
# Update Trip
# ==========================================================

@router.put(
    "/{trip_id}",
    summary="Update trip",
)
async def update_trip(
    trip_id: str,
    payload: TripUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Update a trip owned by the authenticated user.
    """

    trip = await service.update(
        db,
        current_user.id,
        trip_id,
        payload,
    )

    return success_response(
        data=TripResponse.model_validate(trip),
        message="Trip updated successfully",
    )


# ==========================================================
# Delete Trip
# ==========================================================

@router.delete(
    "/{trip_id}",
    summary="Delete trip",
)
async def delete_trip(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Soft-delete a trip owned by the authenticated user.
    """

    await service.delete(
        db,
        current_user.id,
        trip_id,
    )

    return success_response(
        message="Trip deleted successfully",
    )