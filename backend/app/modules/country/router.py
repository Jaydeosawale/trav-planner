"""
Country API Router.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import ApiResponse
from app.database.session import get_db
from app.modules.country.schema import (
    CountryListResponse,
    CountryResponse,
)
from app.modules.country.service import CountryService

router = APIRouter()

service = CountryService()


# ==========================================================
# Get All Countries
# ==========================================================

@router.get(
    "",
    response_model=ApiResponse[list[CountryListResponse]],
)
async def get_countries(
    db: AsyncSession = Depends(get_db),
):
    countries = await service.get_all(db)

    return ApiResponse.success(
        data=countries,
        message="Countries fetched successfully.",
    )


# ==========================================================
# Get Active Countries
# ==========================================================

@router.get(
    "/active",
    response_model=ApiResponse[list[CountryListResponse]],
)
async def get_active_countries(
    db: AsyncSession = Depends(get_db),
):
    countries = await service.get_active(db)

    return ApiResponse.success(
        data=countries,
        message="Active countries fetched successfully.",
    )


# ==========================================================
# Get Country by ID
# ==========================================================

@router.get(
    "/{country_id}",
    response_model=ApiResponse[CountryResponse],
)
async def get_country(
    country_id: str,
    db: AsyncSession = Depends(get_db),
):
    country = await service.get_by_id(
        db,
        country_id,
    )

    return ApiResponse.success(
        data=country,
        message="Country fetched successfully.",
    )


# ==========================================================
# Get Country by ISO2
# ==========================================================

@router.get(
    "/iso2/{iso2}",
    response_model=ApiResponse[CountryResponse],
)
async def get_country_by_iso2(
    iso2: str,
    db: AsyncSession = Depends(get_db),
):
    country = await service.get_by_iso2(
        db,
        iso2,
    )

    return ApiResponse.success(
        data=country,
        message="Country fetched successfully.",
    )


# ==========================================================
# Get Country by ISO3
# ==========================================================

@router.get(
    "/iso3/{iso3}",
    response_model=ApiResponse[CountryResponse],
)
async def get_country_by_iso3(
    iso3: str,
    db: AsyncSession = Depends(get_db),
):
    country = await service.get_by_iso3(
        db,
        iso3,
    )

    return ApiResponse.success(
        data=country,
        message="Country fetched successfully.",
    )