"""
City API Router.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import ApiResponse
from app.database.session import get_db

from app.modules.city.schema import (
    CityBase,
    CityListResponse,
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
    cities = await service.get_all(db)

    return ApiResponse.success(
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
    cities = await service.get_active(db)

    return ApiResponse.success(
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

    return ApiResponse.success(
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

    return ApiResponse.success(
        data=cities,
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

    return ApiResponse.success(
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

    return ApiResponse.success(
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

    return ApiResponse.success(
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

    return ApiResponse.success(
        message="City deleted successfully.",
    )