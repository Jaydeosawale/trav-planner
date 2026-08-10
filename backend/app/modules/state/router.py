"""
State API Router.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import ApiResponse
from app.database.session import get_db

from app.modules.state.schema import (
    StateBase,
    StateListResponse,
    StateResponse,
)

from app.modules.state.service import StateService


router = APIRouter()

service = StateService()


# ==========================================================
# Get All States
# ==========================================================

@router.get(
    "/",
    response_model=ApiResponse[list[StateListResponse]],
)
async def get_states(
    db: AsyncSession = Depends(get_db),
):
    states = await service.get_all(db)

    return ApiResponse.success(
        data=states,
        message="States fetched successfully.",
    )


# ==========================================================
# Get Active States
# ==========================================================

@router.get(
    "/active",
    response_model=ApiResponse[list[StateListResponse]],
)
async def get_active_states(
    db: AsyncSession = Depends(get_db),
):
    states = await service.get_active(db)

    return ApiResponse.success(
        data=states,
        message="Active states fetched successfully.",
    )


# ==========================================================
# Get States By Country
# ==========================================================

@router.get(
    "/country/{country_id}",
    response_model=ApiResponse[list[StateListResponse]],
)
async def get_states_by_country(
    country_id: str,
    db: AsyncSession = Depends(get_db),
):
    states = await service.get_by_country(
        db,
        country_id,
    )

    return ApiResponse.success(
        data=states,
        message="States fetched successfully.",
    )


# ==========================================================
# Get State
# ==========================================================

@router.get(
    "/{state_id}",
    response_model=ApiResponse[StateResponse],
)
async def get_state(
    state_id: str,
    db: AsyncSession = Depends(get_db),
):
    state = await service.get_by_id(
        db,
        state_id,
    )

    return ApiResponse.success(
        data=state,
        message="State fetched successfully.",
    )


# ==========================================================
# Create State
# ==========================================================

@router.post(
    "/",
    response_model=ApiResponse[StateResponse],
)
async def create_state(
    payload: StateBase,
    db: AsyncSession = Depends(get_db),
):
    state = await service.create(
        db,
        payload,
    )

    return ApiResponse.success(
        data=state,
        message="State created successfully.",
    )


# ==========================================================
# Update State
# ==========================================================

@router.put(
    "/{state_id}",
    response_model=ApiResponse[StateResponse],
)
async def update_state(
    state_id: str,
    payload: StateBase,
    db: AsyncSession = Depends(get_db),
):
    state = await service.update(
        db,
        state_id,
        payload,
    )

    return ApiResponse.success(
        data=state,
        message="State updated successfully.",
    )


# ==========================================================
# Delete State
# ==========================================================

@router.delete(
    "/{state_id}",
    response_model=ApiResponse[None],
)
async def delete_state(
    state_id: str,
    db: AsyncSession = Depends(get_db),
):
    await service.delete(
        db,
        state_id,
    )

    return ApiResponse.success(
        message="State deleted successfully.",
    )