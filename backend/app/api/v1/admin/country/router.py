"""
Admin Country API routes.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.dependencies.admin import get_current_admin
from app.modules.auth.model import User
from app.modules.country.schema import (
    CountryAdminUpdate,
    CountryResponse,
)
from app.modules.country.service import CountryService


router = APIRouter()

service = CountryService()


# ==========================================================
# Admin Country List
# ==========================================================

@router.get(
    "/",
    response_model=list[CountryResponse],
    summary="Get all countries for admin",
)
async def get_admin_countries(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """
    Return all non-deleted countries.

    Admin can see both active and inactive countries.
    """

    return await service.get_all(db)


# ==========================================================
# Admin Country Details
# ==========================================================

@router.get(
    "/{country_id}",
    response_model=CountryResponse,
    summary="Get country by ID for admin",
)
async def get_admin_country(
    country_id: str,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """
    Get country details for Admin.
    """

    country = await service.get_by_id(
        db,
        country_id,
    )

    if country is None:
        raise HTTPException(
            status_code=404,
            detail="Country not found",
        )

    return country


# ==========================================================
# Admin Country Update
# ==========================================================

@router.patch(
    "/{country_id}",
    response_model=CountryResponse,
    summary="Update country status",
)
async def update_country(
    country_id: str,
    payload: CountryAdminUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """
    Activate or deactivate a country.

    Only authenticated Admin users can perform this operation.
    """

    country = await service.admin_update(
        db,
        country_id,
        payload,
    )

    if country is None:
        raise HTTPException(
            status_code=404,
            detail="Country not found",
        )

    return country
