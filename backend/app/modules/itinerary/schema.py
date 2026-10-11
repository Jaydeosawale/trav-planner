"""
Itinerary Pydantic schemas.
"""

from __future__ import annotations

from datetime import date as DateType
from datetime import datetime
from datetime import time
from decimal import Decimal

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field


# ==========================================================
# Itinerary Item Create
# ==========================================================

class ItineraryItemCreate(BaseModel):
    """
    Create an itinerary item.
    """

    place_id: str | None = None

    title: str = Field(
        min_length=1,
        max_length=200,
    )

    description: str | None = None

    activity_type: str = Field(
        default="activity",
        max_length=80,
    )

    start_time: time | None = None

    end_time: time | None = None

    estimated_duration_minutes: int | None = Field(
        default=None,
        ge=1,
    )

    sequence: int = Field(
        default=1,
        ge=1,
    )

    transport_mode: str | None = Field(
        default=None,
        max_length=50,
    )

    latitude: Decimal | None = None

    longitude: Decimal | None = None

    notes: str | None = None


# ==========================================================
# Itinerary Item Update
# ==========================================================

class ItineraryItemUpdate(BaseModel):
    """
    Update an itinerary item.
    """

    place_id: str | None = None

    title: str | None = Field(
        default=None,
        min_length=1,
        max_length=200,
    )

    description: str | None = None

    activity_type: str | None = Field(
        default=None,
        max_length=80,
    )

    start_time: time | None = None

    end_time: time | None = None

    estimated_duration_minutes: int | None = Field(
        default=None,
        ge=1,
    )

    sequence: int | None = Field(
        default=None,
        ge=1,
    )

    transport_mode: str | None = Field(
        default=None,
        max_length=50,
    )

    latitude: Decimal | None = None

    longitude: Decimal | None = None

    notes: str | None = None


# ==========================================================
# Itinerary Item Response
# ==========================================================

class ItineraryItemResponse(BaseModel):
    """
    Itinerary item response.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    itinerary_day_id: str

    place_id: str | None

    title: str

    description: str | None

    activity_type: str

    start_time: time | None

    end_time: time | None

    estimated_duration_minutes: int | None

    sequence: int

    transport_mode: str | None

    latitude: Decimal | None

    longitude: Decimal | None

    notes: str | None

    created_at: datetime

    updated_at: datetime


# ==========================================================
# Itinerary Day Create
# ==========================================================

class ItineraryDayCreate(BaseModel):
    """
    Create an itinerary day.
    """

    day_number: int = Field(
        ge=1,
    )

    date: DateType

    title: str | None = Field(
        default=None,
        max_length=200,
    )

    notes: str | None = None


# ==========================================================
# Itinerary Day Update
# ==========================================================

class ItineraryDayUpdate(BaseModel):
    """
    Update an itinerary day.
    """

    day_number: int | None = Field(
        default=None,
        ge=1,
    )

    date: DateType | None = None

    title: str | None = Field(
        default=None,
        max_length=200,
    )

    notes: str | None = None


# ==========================================================
# Itinerary Day Response
# ==========================================================

class ItineraryDayResponse(BaseModel):
    """
    Itinerary day response.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    trip_id: str

    day_number: int

    date: DateType

    title: str | None

    notes: str | None

    created_at: datetime

    updated_at: datetime

    items: list[ItineraryItemResponse] = Field(
        default_factory=list,
    )


# ==========================================================
# Complete Itinerary Response
# ==========================================================

class ItineraryResponse(BaseModel):
    """
    Complete itinerary for a trip.
    """

    trip_id: str

    days: list[ItineraryDayResponse]
