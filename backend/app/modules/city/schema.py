"""
City Pydantic Schemas.
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field


# ==========================================================
# Base
# ==========================================================

class CityBase(BaseModel):
    """
    Shared city fields.
    """

    country_id: str

    state_id: str

    name: str = Field(
        min_length=2,
        max_length=150,
        examples=["Mumbai"],
    )

    latitude: Decimal | None = None

    longitude: Decimal | None = None

    is_active: bool = True


# ==========================================================
# Response
# ==========================================================

class CityResponse(CityBase):
    """
    City response.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    created_at: datetime

    updated_at: datetime


# ==========================================================
# List Response
# ==========================================================

class CityListResponse(BaseModel):
    """
    Lightweight city response.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    country_id: str

    state_id: str

    name: str

    is_active: bool