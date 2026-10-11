"""
Trip Pydantic schemas.
"""

from __future__ import annotations

from datetime import date
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field


# ==========================================================
# Create
# ==========================================================

class TripCreate(BaseModel):
    """
    Create a user trip.
    """

    destination_id: str

    planner_id: str | None = None

    title: str = Field(
        min_length=2,
        max_length=200,
    )

    start_date: date

    end_date: date

    travelers: int = Field(
        default=1,
        ge=1,
    )

    budget_amount: Decimal | None = Field(
        default=None,
        ge=0,
    )

    budget_currency: str = Field(
        default="INR",
        min_length=3,
        max_length=3,
    )

    travel_style: str | None = Field(
        default=None,
        max_length=100,
    )

    notes: str | None = None


# ==========================================================
# Update
# ==========================================================

class TripUpdate(BaseModel):
    """
    Update a user trip.
    """

    destination_id: str | None = None

    planner_id: str | None = None

    title: str | None = Field(
        default=None,
        min_length=2,
        max_length=200,
    )

    start_date: date | None = None

    end_date: date | None = None

    travelers: int | None = Field(
        default=None,
        ge=1,
    )

    budget_amount: Decimal | None = Field(
        default=None,
        ge=0,
    )

    budget_currency: str | None = Field(
        default=None,
        min_length=3,
        max_length=3,
    )

    travel_style: str | None = Field(
        default=None,
        max_length=100,
    )

    notes: str | None = None

    status: str | None = Field(
        default=None,
        max_length=50,
    )


# ==========================================================
# Response
# ==========================================================

class TripResponse(BaseModel):
    """
    Full trip response.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    user_id: str

    planner_id: str | None

    destination_id: str

    title: str

    start_date: date

    end_date: date

    travelers: int

    budget_amount: Decimal | None

    budget_currency: str

    travel_style: str | None

    notes: str | None

    status: str

    created_at: datetime

    updated_at: datetime


# ==========================================================
# List Response
# ==========================================================

class TripListResponse(BaseModel):
    """
    Lightweight trip response.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    planner_id: str | None

    destination_id: str

    title: str

    start_date: date

    end_date: date

    travelers: int

    budget_amount: Decimal | None

    budget_currency: str

    status: str


# ==========================================================
# Paginated Response
# ==========================================================

class TripPaginatedResponse(BaseModel):
    """
    Paginated trips.
    """

    items: list[TripListResponse]

    total: int

    page: int

    size: int

    pages: int