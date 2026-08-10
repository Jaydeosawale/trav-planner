"""
Planner API Router.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import ApiResponse
from app.database.session import get_db
from app.dependencies.current_user import get_current_user
from app.modules.auth.model import User
from app.modules.planner.schema import (
    PlannerCreate,
    PlannerListResponse,
    PlannerResponse,
    PlannerUpdate,
)
from app.modules.planner.service import PlannerService


router = APIRouter()

service = PlannerService()


# ==========================================================
# Get All Planners
# ==========================================================

@router.get(
    "/",
    response_model=ApiResponse[list[PlannerListResponse]],
)
async def get_planners(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    planners = await service.get_all(
        db,
        current_user.id,
    )

    return ApiResponse.success(
        data=planners,
        message="Planners fetched successfully.",
    )


# ==========================================================
# Get Planner
# ==========================================================

@router.get(
    "/{planner_id}",
    response_model=ApiResponse[PlannerResponse],
)
async def get_planner(
    planner_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    planner = await service.get_by_id(
        db,
        planner_id,
        current_user.id,
    )

    return ApiResponse.success(
        data=planner,
        message="Planner fetched successfully.",
    )


# ==========================================================
# Create Planner
# ==========================================================

@router.post(
    "/",
    response_model=ApiResponse[PlannerResponse],
)
async def create_planner(
    payload: PlannerCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    planner = await service.create(
        db,
        current_user.id,
        payload,
    )

    return ApiResponse.success(
        data=planner,
        message="Planner created successfully.",
    )


# ==========================================================
# Update Planner
# ==========================================================

@router.put(
    "/{planner_id}",
    response_model=ApiResponse[PlannerResponse],
)
async def update_planner(
    planner_id: str,
    payload: PlannerUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    planner = await service.update(
        db,
        planner_id,
        current_user.id,
        payload,
    )

    return ApiResponse.success(
        data=planner,
        message="Planner updated successfully.",
    )


# ==========================================================
# Delete Planner
# ==========================================================

@router.delete(
    "/{planner_id}",
    response_model=ApiResponse[None],
)
async def delete_planner(
    planner_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await service.delete(
        db,
        planner_id,
        current_user.id,
    )

    return ApiResponse.success(
        message="Planner deleted successfully.",
    )