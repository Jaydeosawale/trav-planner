from __future__ import annotations

from pydantic import BaseModel, Field


class SharedLocation(BaseModel):
    latitude: float = Field(ge=-90, le=90, allow_inf_nan=False)
    longitude: float = Field(ge=-180, le=180, allow_inf_nan=False)


class AIChatRequest(BaseModel):
    message: str = Field(
        min_length=1,
        max_length=10000,
    )

    session_id: str | None = Field(default=None, max_length=36)
    location: SharedLocation | None = None


class AIChatData(BaseModel):
    content: str
    agent: str
    success: bool
    data: dict
    metadata: dict


class AIChatResponse(BaseModel):
    success: bool
    data: AIChatData
    message: str | None = None


class TripBrief(BaseModel):
    origin: str = Field(default='', max_length=200)
    destination: str = Field(default='', max_length=200)
    dates: str = Field(default='', max_length=200)
    travelers: int = Field(default=1, ge=1, le=100)
    budget: str = Field(default='', max_length=200)
    transport: str = Field(default='', max_length=200)
    interests: str = Field(default='', max_length=500)
    food: str = Field(default='', max_length=300)
    pace: str = Field(default='', max_length=100)


class ConversationDraft(BaseModel):
    title: str = Field(default='My travel ideas', min_length=1, max_length=120)
    brief: TripBrief = Field(default_factory=TripBrief)
    version: int | None = Field(default=None, ge=0)
