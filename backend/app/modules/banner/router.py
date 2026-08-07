from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.modules.banner.schema import BannerCreate
from app.modules.banner.schema import BannerResponse
from app.modules.banner.schema import BannerUpdate
from app.modules.banner.service import BannerService

router = APIRouter()

service = BannerService()


@router.get(
    "/",
    response_model=list[BannerResponse],
    summary="Get all banners",
)
async def get_banners(
    db: AsyncSession = Depends(get_db),
):
    return await service.get_all(db)


@router.get(
    "/{banner_id}",
    response_model=BannerResponse,
    summary="Get banner by ID",
)
async def get_banner(
    banner_id: str,
    db: AsyncSession = Depends(get_db),
):
    banner = await service.get_by_id(
        db,
        banner_id,
    )

    if banner is None:
        raise HTTPException(
            status_code=404,
            detail="Banner not found",
        )

    return banner


@router.post(
    "/",
    response_model=BannerResponse,
    status_code=201,
    summary="Create banner",
)
async def create_banner(
    payload: BannerCreate,
    db: AsyncSession = Depends(get_db),
):
    return await service.create(
        db,
        payload,
    )


@router.put(
    "/{banner_id}",
    response_model=BannerResponse,
    summary="Update banner",
)
async def update_banner(
    banner_id: str,
    payload: BannerUpdate,
    db: AsyncSession = Depends(get_db),
):
    banner = await service.update(
        db,
        banner_id,
        payload,
    )

    if banner is None:
        raise HTTPException(
            status_code=404,
            detail="Banner not found",
        )

    return banner


@router.delete(
    "/{banner_id}",
    summary="Delete banner",
)
async def delete_banner(
    banner_id: str,
    db: AsyncSession = Depends(get_db),
):
    deleted = await service.delete(
        db,
        banner_id,
    )

    if not deleted:
        raise HTTPException(
            status_code=404,
            detail="Banner not found",
        )

    return {
        "message": "Banner deleted successfully",
    }