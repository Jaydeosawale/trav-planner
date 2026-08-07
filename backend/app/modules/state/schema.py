"""
State Pydantic Schemas.
"""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field


# ==========================================================
# Base
# ==========================================================

class StateBase(BaseModel):
    """
    Shared state fields.
    """

    country_id: str

    name: str = Field(
        min_length=2,
        max_length=150,
        examples=["Maharashtra"],
    )

    code: str = Field(
        min_length=1,
        max_length=20,
        examples=["MH"],
    )

    is_active: bool = True


# ==========================================================
# Response
# ==========================================================

class StateResponse(StateBase):
    """
    State response.
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

class StateListResponse(BaseModel):
    """
    Lightweight state response.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str

    country_id: str

    name: str

    code: str

    is_active: bool