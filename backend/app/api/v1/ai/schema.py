from __future__ import annotations

from pydantic import BaseModel, Field


class AIChatRequest(BaseModel):
    message: str = Field(
        min_length=1,
        max_length=10000,
    )

    session_id: str | None = None


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
