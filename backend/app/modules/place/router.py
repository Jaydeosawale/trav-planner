"""
Public Place API routes.

These endpoints are intended for:
- Normal users
- Flutter application
- Search
- Recommendation engine
- AI agents
- Trip planner
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from fastapi import Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import ApiResponse
from app.common.responses.api_response import success_response
from app.database.session import get_db
from app.modules.place.schema import PlacePaginatedResponse
from app.modules.place.schema import PlaceResponse
from app.modules.place.service import PlaceService


router = APIRouter()

service = PlaceService()


# ==========================================================
# Search / Paginated Search
# IMPORTANT:
# Must be before /{place_id}
# ==========================================================

@router.get(
    "/search",
    response_model=ApiResponse[PlacePaginatedResponse],
    summary="Search active places",
)
async def search_places(
    page: int = Query(
        default=1,
        ge=1,
    ),
    size: int = Query(
        default=50,
        ge=1,
        le=100,
    ),
    search: str | None = Query(
        default=None,
        min_length=1,
    ),
    country_id: str | None = Query(
        default=None,
    ),
    state_id: str | None = Query(
        default=None,
    ),
    city_id: str | None = Query(
        default=None,
    ),
    place_type: str | None = Query(
        default=None,
    ),
    category_id: str | None = Query(
        default=None,
    ),
    db: AsyncSession = Depends(get_db),
):
    """
    Search active places.

    Supports:

    - Text search
    - Country
    - State / Province
    - City
    - Category
    - Place type
    - Pagination

    Used by:
    - Normal users
    - Flutter application
    - AI search
    - Recommendation engine
    - Trip planner
    """

    places, total = await service.search(
        db,
        page=page,
        size=size,
        search=search,
        country_id=country_id,
        state_id=state_id,
        city_id=city_id,
        place_type=place_type,
        category_id=category_id,
    )

    pages = (
        (total + size - 1) // size
        if total > 0
        else 0
    )

    data = PlacePaginatedResponse(
        items=places,
        total=total,
        page=page,
        size=size,
        pages=pages,
    )

    return success_response(
        data=data,
        message="Places fetched successfully",
    )


# ==========================================================
# Get All
# ==========================================================

@router.get(
    "/",
    summary="Get active places",
)
async def get_places(
    db: AsyncSession = Depends(get_db),
):
    """
    Return active, non-deleted places.

    Inactive places must never be shown to normal users
    or AI discovery unless explicitly requested by Admin.
    """

    places = await service.get_all(
        db,
        active_only=True,
    )

    return success_response(
        data=[
            PlaceResponse.model_validate(place)
            for place in places
        ],
        message="Places retrieved successfully",
    )


# ==========================================================
# Get By ID
# ==========================================================

@router.get(
    "/{place_id}",
    summary="Get active place by ID",
)
async def get_place(
    place_id: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Get an active place by ID.
    """

    place = await service.get_by_id(
        db,
        place_id,
        active_only=True,
    )

    return success_response(
        data=PlaceResponse.model_validate(place),
        message="Place retrieved successfully",
    )


# ==========================================================
# Get By Slug
# ==========================================================

@router.get(
    "/slug/{slug}",
    summary="Get active place by slug",
)
async def get_place_by_slug(
    slug: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Get an active place by slug.
    """

    place = await service.get_by_slug(
        db,
        slug,
        active_only=True,
    )

    return success_response(
        data=PlaceResponse.model_validate(place),
        message="Place retrieved successfully",
    )