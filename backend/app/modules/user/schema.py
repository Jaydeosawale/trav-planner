"""
User travel profile and behavior schemas.
"""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field


# ==========================================================
# Travel Profile
# ==========================================================

class UserTravelProfileCreate(BaseModel):
    travel_style: str | None = Field(
        default=None,
        max_length=100,
    )

    budget_level: str | None = Field(
        default=None,
        max_length=50,
    )

    preferred_transport: str | None = Field(
        default=None,
        max_length=100,
    )

    accommodation_preference: str | None = Field(
        default=None,
        max_length=100,
    )

    food_preference: str | None = Field(
        default=None,
        max_length=100,
    )

    interests: str | None = None

    other_preferences: str | None = None


class UserTravelProfileUpdate(
    UserTravelProfileCreate
):
    pass


class UserTravelProfileResponse(
    UserTravelProfileCreate
):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime


# ==========================================================
# Search History
# ==========================================================

class UserSearchHistoryCreate(BaseModel):
    query: str = Field(
        min_length=1,
        max_length=500,
    )

    search_type: str = Field(
        default="place",
        max_length=50,
    )

    filters_text: str | None = None


class UserSearchHistoryResponse(
    UserSearchHistoryCreate
):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str
    user_id: str
    created_at: datetime


# ==========================================================
# Place Interaction
# ==========================================================

class UserPlaceInteractionResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str
    user_id: str
    place_id: str
    created_at: datetime


class UserPlaceViewResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str
    user_id: str
    place_id: str
    viewed_at: datetime