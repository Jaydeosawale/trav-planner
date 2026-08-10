"""
Planner Pydantic schemas.
"""

from __future__ import annotations

from datetime import date
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field


# ==========================================================
# Create Planner
# ==========================================================

class PlannerCreate(BaseModel):
    """
    Create a travel planning request.
    """

    destination_id: str

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

    preferences: str | None = None


# ==========================================================
# Update Planner
# ==========================================================

class PlannerUpdate(BaseModel):
    """
    Update an existing planning request.
    """

    destination_id: str | None = None

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

    preferences: str | None = None


# ==========================================================
# Planner Response
# ==========================================================

class PlannerResponse(BaseModel):
    """
    Public planner representation.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    user_id: str

    destination_id: str

    title: str

    start_date: date

    end_date: date

    travelers: int

    budget_amount: Decimal | None

    budget_currency: str

    travel_style: str | None

    preferences: str | None

    status: str

    created_at: datetime

    updated_at: datetime


# ==========================================================
# Planner List Response
# ==========================================================

class PlannerListResponse(BaseModel):
    """
    Lightweight planner representation.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    destination_id: str

    title: str

    start_date: date

    end_date: date

    travelers: int

    budget_amount: Decimal | None

    budget_currency: str

    travel_style: str | None

    status: str