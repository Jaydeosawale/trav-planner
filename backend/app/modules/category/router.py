from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from fastapi import status
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import ApiResponse
from app.database.session import get_db
from app.modules.category.schema import (
    CategoryCreate,
    CategoryResponse,
    CategoryUpdate,
)
from app.modules.category.service import CategoryService

router = APIRouter()

service = CategoryService()


@router.get(
    "",
    response_model=ApiResponse[list[CategoryResponse]],
)
async def get_categories(
    db: AsyncSession = Depends(get_db),
):
    categories = await service.get_all(db)

    return ApiResponse.success(
        data=categories,
        message="Categories fetched successfully.",
    )


@router.get(
    "/{category_id}",
    response_model=ApiResponse[CategoryResponse],
)
async def get_category(
    category_id: str,
    db: AsyncSession = Depends(get_db),
):
    category = await service.get_by_id(
        db,
        category_id,
    )

    return ApiResponse.success(
        data=category,
        message="Category fetched successfully.",
    )


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=ApiResponse[CategoryResponse],
)
async def create_category(
    payload: CategoryCreate,
    db: AsyncSession = Depends(get_db),
):
    category = await service.create(
        db,
        payload,
    )

    return ApiResponse.success(
        data=category,
        message="Category created successfully.",
    )


@router.put(
    "/{category_id}",
    response_model=ApiResponse[CategoryResponse],
)
async def update_category(
    category_id: str,
    payload: CategoryUpdate,
    db: AsyncSession = Depends(get_db),
):
    category = await service.update(
        db,
        category_id,
        payload,
    )

    return ApiResponse.success(
        data=category,
        message="Category updated successfully.",
    )


@router.delete(
    "/{category_id}",
    response_model=ApiResponse[None],
)
async def delete_category(
    category_id: str,
    db: AsyncSession = Depends(get_db),
):
    await service.delete(
        db,
        category_id,
    )

    return ApiResponse.success(
        message="Category deleted successfully.",
    )


@router.get(
    "/featured",
    response_model=ApiResponse[list[CategoryResponse]],
)
async def get_featured_categories(
    db: AsyncSession = Depends(get_db),
):
    categories = await service.get_featured(
        db,
    )

    return ApiResponse.success(
        data=categories,
        message="Featured categories fetched successfully.",
    )


@router.get(
    "/active",
    response_model=ApiResponse[list[CategoryResponse]],
)
async def get_active_categories(
    db: AsyncSession = Depends(get_db),
):
    categories = await service.get_active(
        db,
    )

    return ApiResponse.success(
        data=categories,
        message="Active categories fetched successfully.",
    )


@router.get(
    "/root",
    response_model=ApiResponse[list[CategoryResponse]],
)
async def get_root_categories(
    db: AsyncSession = Depends(get_db),
):
    categories = await service.get_root_categories(
        db,
    )

    return ApiResponse.success(
        data=categories,
        message="Root categories fetched successfully.",
    )


@router.get(
    "/{category_id}/children",
    response_model=ApiResponse[list[CategoryResponse]],
)
async def get_children(
    category_id: str,
    db: AsyncSession = Depends(get_db),
):
    categories = await service.get_children(
        db,
        category_id,
    )

    return ApiResponse.success(
        data=categories,
        message="Child categories fetched successfully.",
    )