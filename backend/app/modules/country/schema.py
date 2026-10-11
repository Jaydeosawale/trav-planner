"""
Country Pydantic Schemas.
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel
from pydantic import ConfigDict


# ==========================================================
# Response
# ==========================================================

class CountryResponse(BaseModel):
    """
    Country response schema.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    name: str

    iso2: str

    iso3: str

    phone_code: str

    currency_code: str

    currency_name: str

    capital: str

    continent: str

    timezone: str

    flag_url: str | None

    latitude: Decimal | None

    longitude: Decimal | None

    is_active: bool

    created_at: datetime

    updated_at: datetime


# ==========================================================
# List Response
# ==========================================================

class CountryListResponse(BaseModel):
    """
    Lightweight country response.
    Used for dropdowns and search.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    name: str

    iso2: str

    flag_url: str | None

    is_active: bool


    # ==========================================================
# Admin Update
# ==========================================================

class CountryAdminUpdate(BaseModel):
    """
    Admin-only country update.

    For now, Admin controls only whether the country
    is available to users.
    """

    is_active: bool