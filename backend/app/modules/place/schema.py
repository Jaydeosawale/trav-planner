"""
Place schemas.
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field

# ==========================================================
# Create Place
# ==========================================================


class PlaceCreate(BaseModel):
    """
    Place creation payload.
    """

    city_id: str

    category_id: str | None = None

    name: str = Field(
        min_length=2,
        max_length=200,
    )

    slug: str = Field(
        min_length=2,
        max_length=220,
    )

    place_type: str = Field(
        min_length=2,
        max_length=80,
    )

    short_description: str | None = Field(
        default=None,
        max_length=500,
    )

    description: str | None = None

    address: str | None = Field(
        default=None,
        max_length=500,
    )

    locality: str | None = Field(
        default=None,
        max_length=150,
    )

    postal_code: str | None = Field(
        default=None,
        max_length=30,
    )

    latitude: Decimal | None = None

    longitude: Decimal | None = None

    image_url: str | None = Field(
        default=None,
        max_length=500,
    )

    image_credit: str | None = Field(default=None, max_length=6000)
    visiting_notes: str | None = Field(default=None, max_length=3000)

    provider: str | None = Field(
        default=None,
        max_length=50,
    )

    external_place_id: str | None = Field(
        default=None,
        max_length=200,
    )

    rating: Decimal | None = None

    price_level: int | None = None

    is_featured: bool = False


# ==========================================================
# Update Place
# ==========================================================


class PlaceUpdate(BaseModel):
    """
    Place update payload.
    """

    city_id: str | None = None

    category_id: str | None = None

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

    place_type: str | None = Field(
        default=None,
        min_length=2,
        max_length=80,
    )

    short_description: str | None = Field(
        default=None,
        max_length=500,
    )

    description: str | None = None

    address: str | None = Field(
        default=None,
        max_length=500,
    )

    locality: str | None = Field(
        default=None,
        max_length=150,
    )

    postal_code: str | None = Field(
        default=None,
        max_length=30,
    )

    latitude: Decimal | None = None

    longitude: Decimal | None = None

    image_url: str | None = Field(
        default=None,
        max_length=500,
    )

    image_credit: str | None = Field(default=None, max_length=6000)
    visiting_notes: str | None = Field(default=None, max_length=3000)

    provider: str | None = Field(
        default=None,
        max_length=50,
    )

    external_place_id: str | None = Field(
        default=None,
        max_length=200,
    )

    rating: Decimal | None = None

    price_level: int | None = None

    is_featured: bool | None = None

    is_active: bool | None = None


# ==========================================================
# Response
# ==========================================================


class PlaceResponse(BaseModel):
    """
    Public place representation.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    city_id: str
    city_name: str | None = None
    country_id: str | None = None
    category_id: str | None

    name: str
    slug: str
    place_type: str

    short_description: str | None
    description: str | None

    address: str | None
    locality: str | None
    postal_code: str | None

    latitude: Decimal | None
    longitude: Decimal | None

    image_url: str | None

    is_discovery: bool = False
    image_credit: str | None = None
    visiting_notes: str | None = None

    provider: str | None
    external_place_id: str | None

    rating: Decimal | None
    price_level: int | None

    is_featured: bool
    is_active: bool

    created_at: datetime
    updated_at: datetime

    # ==========================================================


# Paginated Response
# ==========================================================


class PlacePaginatedResponse(BaseModel):
    """
    Paginated place response.

    Used by search, Admin CMS, and future AI retrieval.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    items: list[PlaceResponse]

    total: int

    page: int

    size: int

    pages: int
