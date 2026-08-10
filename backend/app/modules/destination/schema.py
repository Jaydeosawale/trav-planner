"""
Destination schemas.
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field


# ==========================================================
# Create Destination
# ==========================================================

class DestinationCreate(BaseModel):
    """
    Destination creation payload.
    """

    city_id: str

    name: str = Field(
        min_length=2,
        max_length=200,
    )

    slug: str = Field(
        min_length=2,
        max_length=220,
    )

    short_description: str | None = Field(
        default=None,
        max_length=500,
    )

    description: str | None = None

    image_url: str | None = Field(
        default=None,
        max_length=500,
    )

    latitude: Decimal | None = None

    longitude: Decimal | None = None

    is_featured: bool = False


# ==========================================================
# Update Destination
# ==========================================================

class DestinationUpdate(BaseModel):
    """
    Destination update payload.
    """

    city_id: str | None = None

    name: str | None = Field(
        default=None,
        min_length=2,
        max_length=200,
    )

    slug: str | None = Field(
        default=None,
        min_length=2,
        max_length=220,
    )

    short_description: str | None = Field(
        default=None,
        max_length=500,
    )

    description: str | None = None

    image_url: str | None = Field(
        default=None,
        max_length=500,
    )

    latitude: Decimal | None = None

    longitude: Decimal | None = None

    is_featured: bool | None = None

    is_active: bool | None = None


# ==========================================================
# Destination Response
# ==========================================================

class DestinationResponse(BaseModel):
    """
    Public destination representation.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str
    city_id: str

    name: str
    slug: str

    short_description: str | None
    description: str | None

    image_url: str | None

    latitude: Decimal | None
    longitude: Decimal | None

    is_featured: bool
    is_active: bool

    created_at: datetime
    updated_at: datetime