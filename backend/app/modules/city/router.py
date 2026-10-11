"""
City API Router.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from fastapi import Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import (
    ApiResponse,
    success_response,
)

from app.database.session import get_db

from app.modules.city.schema import (
    CityBase,
    CityListResponse,
    CityPaginatedResponse,
    CityResponse,
)

from app.modules.city.service import CityService


router = APIRouter()

service = CityService()


# ==========================================================
# Get All Cities
# ==========================================================

@router.get(
    "/",
    response_model=ApiResponse[list[CityListResponse]],
)
async def get_cities(
    db: AsyncSession = Depends(get_db),
):
    cities = await service.get_all(
        db,
    )

    return success_response(
        data=cities,
        message="Cities fetched successfully.",
    )


# ==========================================================
# Get Active Cities
# ==========================================================

@router.get(
    "/active",
    response_model=ApiResponse[list[CityListResponse]],
)
async def get_active_cities(
    db: AsyncSession = Depends(get_db),
):
    cities = await service.get_active(
        db,
    )

    return success_response(
        data=cities,
        message="Active cities fetched successfully.",
    )


# ==========================================================
# Get Cities By Country
# ==========================================================

@router.get(
    "/country/{country_id}",
    response_model=ApiResponse[list[CityListResponse]],
)
async def get_cities_by_country(
    country_id: str,
    db: AsyncSession = Depends(get_db),
):
    cities = await service.get_by_country(
        db,
        country_id,
    )

    return success_response(
        data=cities,
        message="Cities fetched successfully.",
    )


# ==========================================================
# Get Cities By State
# ==========================================================

@router.get(
    "/state/{state_id}",
    response_model=ApiResponse[list[CityListResponse]],
)
async def get_cities_by_state(
    state_id: str,
    db: AsyncSession = Depends(get_db),
):
    cities = await service.get_by_state(
        db,
        state_id,
    )

    return success_response(
        data=cities,
        message="Cities fetched successfully.",
    )


# ==========================================================
# Search / Paginated Cities
# IMPORTANT: Must be before /{city_id}
# ==========================================================

@router.get(
    "/search",
    response_model=ApiResponse[CityPaginatedResponse],
)
async def search_cities(
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
    db: AsyncSession = Depends(get_db),
):
    cities, total = await service.search(
        db,
        page=page,
        size=size,
        search=search,
        country_id=country_id,
        state_id=state_id,
    )

    pages = (
        (total + size - 1) // size
        if total > 0
        else 0
    )

    data = CityPaginatedResponse(
        items=cities,
        total=total,
        page=page,
        size=size,
        pages=pages,
    )

    return success_response(
        data=data,
        message="Cities fetched successfully.",
    )


# ==========================================================
# Get City
# ==========================================================

@router.get(
    "/{city_id}",
    response_model=ApiResponse[CityResponse],
)
async def get_city(
    city_id: str,
    db: AsyncSession = Depends(get_db),
):
    city = await service.get_by_id(
        db,
        city_id,
    )

    return success_response(
        data=city,
        message="City fetched successfully.",
    )


# ==========================================================
# Create City
# ==========================================================

@router.post(
    "/",
    response_model=ApiResponse[CityResponse],
)
async def create_city(
    payload: CityBase,
    db: AsyncSession = Depends(get_db),
):
    city = await service.create(
        db,
        payload,
    )

    return success_response(
        data=city,
        message="City created successfully.",
    )


# ==========================================================
# Update City
# ==========================================================

@router.put(
    "/{city_id}",
    response_model=ApiResponse[CityResponse],
)
async def update_city(
    city_id: str,
    payload: CityBase,
    db: AsyncSession = Depends(get_db),
):
    city = await service.update(
        db,
        city_id,
        payload,
    )

    return success_response(
        data=city,
        message="City updated successfully.",
    )


# ==========================================================
# Delete City
# ==========================================================

@router.delete(
    "/{city_id}",
    response_model=ApiResponse[None],
)
async def delete_city(
    city_id: str,
    db: AsyncSession = Depends(get_db),
):
    await service.delete(
        db,
        city_id,
    )

    return success_response(
        message="City deleted successfully.",
    )