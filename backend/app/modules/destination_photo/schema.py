"""
Destination Photo Pydantic Schemas.
"""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field


# ==========================================================
# Create
# ==========================================================


class DestinationPhotoCreate(BaseModel):
    """
    Create destination photo.
    """

    image_url: str = Field(
        min_length=1,
        max_length=1000,
    )

    caption: str | None = Field(
        default=None,
        max_length=300,
    )

    display_order: int = Field(
        default=0,
        ge=0,
    )

    is_cover: bool = False

    is_active: bool = True


# ==========================================================
# Update
# ==========================================================


class DestinationPhotoUpdate(BaseModel):
    """
    Update destination photo.
    """

    image_url: str | None = Field(
        default=None,
        min_length=1,
        max_length=1000,
    )

    caption: str | None = Field(
        default=None,
        max_length=300,
    )

    display_order: int | None = Field(
        default=None,
        ge=0,
    )

    is_cover: bool | None = None

    is_active: bool | None = None


# ==========================================================
# Response
# ==========================================================


class DestinationPhotoResponse(BaseModel):
    """
    Destination photo response.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    destination_id: str

    image_url: str

    caption: str | None

    display_order: int

    is_cover: bool

    is_active: bool

    created_at: datetime

    updated_at: datetime