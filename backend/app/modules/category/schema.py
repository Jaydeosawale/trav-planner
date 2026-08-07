"""
Category Pydantic Schemas.
"""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field


# ==========================================================
# Base
# ==========================================================

class CategoryBase(BaseModel):
    """
    Shared category fields.
    """

    name: str = Field(
        min_length=2,
        max_length=150,
        examples=["Adventure"],
    )

    description: str | None = Field(
        default=None,
        max_length=2000,
    )

    icon: str | None = Field(
        default=None,
        max_length=500,
    )

    image_url: str | None = Field(
        default=None,
        max_length=1000,
    )

    parent_id: str | None = None

    display_order: int = Field(
        default=0,
        ge=0,
    )

    is_featured: bool = False

    is_active: bool = True


# ==========================================================
# Create
# ==========================================================

class CategoryCreate(CategoryBase):
    """
    Create category request.
    """

    pass


# ==========================================================
# Update
# ==========================================================

class CategoryUpdate(BaseModel):
    """
    Update category request.
    """

    name: str | None = Field(
        default=None,
        min_length=2,
        max_length=150,
    )

    description: str | None = None

    icon: str | None = None

    image_url: str | None = None

    parent_id: str | None = None

    display_order: int | None = Field(
        default=None,
        ge=0,
    )

    is_featured: bool | None = None

    is_active: bool | None = None


# ==========================================================
# Response
# ==========================================================

class CategoryResponse(CategoryBase):
    """
    Category response.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    slug: str

    created_at: datetime

    updated_at: datetime


# ==========================================================
# Tree Response
# ==========================================================

class CategoryTreeResponse(CategoryResponse):
    """
    Category tree response.
    """

    children: list["CategoryTreeResponse"] = []


CategoryTreeResponse.model_rebuild()