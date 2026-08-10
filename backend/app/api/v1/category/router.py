"""
Category API v1 endpoints.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from fastapi import Path
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import success_response
from app.database.session import get_db
from app.modules.category.schema import CategoryCreate
from app.modules.category.schema import CategoryResponse
from app.modules.category.schema import CategoryUpdate
from app.modules.category.service import CategoryService
from app.common.constants.not_found import NotFoundException


router = APIRouter()

service = CategoryService()


# ==========================================================
# Get All Categories
# ==========================================================


@router.get(
    "/",
    summary="Get all categories",
)
async def get_categories(
    db: AsyncSession = Depends(get_db),
):
    """
    Return all categories.
    """

    categories = await service.repository.get_all(db)

    return success_response(
        data=[
            CategoryResponse.model_validate(category)
            for category in categories
        ],
        message="Categories retrieved successfully",
    )


# ==========================================================
# Get Active Categories
# ==========================================================


@router.get(
    "/active",
    summary="Get active categories",
)
async def get_active_categories(
    db: AsyncSession = Depends(get_db),
):
    """
    Return active categories.
    """

    categories = await service.get_active(db)

    return success_response(
        data=[
            CategoryResponse.model_validate(category)
            for category in categories
        ],
        message="Active categories retrieved successfully",
    )


# ==========================================================
# Get Featured Categories
# ==========================================================


@router.get(
    "/featured",
    summary="Get featured categories",
)
async def get_featured_categories(
    db: AsyncSession = Depends(get_db),
):
    """
    Return featured categories.
    """

    categories = await service.get_featured(db)

    return success_response(
        data=[
            CategoryResponse.model_validate(category)
            for category in categories
        ],
        message="Featured categories retrieved successfully",
    )


# ==========================================================
# Get Root Categories
# ==========================================================


@router.get(
    "/roots",
    summary="Get root categories",
)
async def get_root_categories(
    db: AsyncSession = Depends(get_db),
):
    """
    Return top-level categories.
    """

    categories = await service.get_root_categories(db)

    return success_response(
        data=[
            CategoryResponse.model_validate(category)
            for category in categories
        ],
        message="Root categories retrieved successfully",
    )


# ==========================================================
# Get Child Categories
# ==========================================================


@router.get(
    "/{parent_id}/children",
    summary="Get child categories",
)
async def get_children(
    parent_id: str = Path(
        ...,
        description="Parent category ID",
    ),
    db: AsyncSession = Depends(get_db),
):
    """
    Return children of a category.
    """

    categories = await service.get_children(
        db,
        parent_id,
    )

    return success_response(
        data=[
            CategoryResponse.model_validate(category)
            for category in categories
        ],
        message="Child categories retrieved successfully",
    )


# ==========================================================
# Get Category
# ==========================================================


@router.get(
    "/{category_id}",
    summary="Get category by ID",
)
async def get_category(
    category_id: str = Path(
        ...,
        description="Category ID",
    ),
    db: AsyncSession = Depends(get_db),
):
    """
    Return a single category.
    """

    category = await service.repository.get_by_id(
        db,
        category_id,
    )

    if category is None:
     raise NotFoundException("Category")

    return success_response(
        data=CategoryResponse.model_validate(category),
        message="Category retrieved successfully",
    )


# ==========================================================
# Create Category
# ==========================================================


@router.post(
    "/",
    summary="Create category",
)
async def create_category(
    payload: CategoryCreate,
    db: AsyncSession = Depends(get_db),
):
    """
    Create a new category.
    """

    category = await service.create(
        db,
        payload,
    )

    return success_response(
        data=CategoryResponse.model_validate(category),
        message="Category created successfully",
    )


# ==========================================================
# Update Category
# ==========================================================


@router.put(
    "/{category_id}",
    summary="Update category",
)
async def update_category(
    payload: CategoryUpdate,
    category_id: str = Path(
        ...,
        description="Category ID",
    ),
    db: AsyncSession = Depends(get_db),
):
    """
    Update an existing category.
    """

    category = await service.update(
        db,
        category_id,
        payload,
    )

    return success_response(
        data=CategoryResponse.model_validate(category),
        message="Category updated successfully",
    )


# ==========================================================
# Delete Category
# ==========================================================


@router.delete(
    "/{category_id}",
    summary="Delete category",
)
async def delete_category(
    category_id: str = Path(
        ...,
        description="Category ID",
    ),
    db: AsyncSession = Depends(get_db),
):
    """
    Soft delete a category.
    """

    await service.delete(
        db,
        category_id,
    )

    return success_response(
        data=None,
        message="Category deleted successfully",
    )