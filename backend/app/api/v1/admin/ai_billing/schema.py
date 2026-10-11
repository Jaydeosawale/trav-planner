from __future__ import annotations

from pydantic import BaseModel, Field


class AIBillingEnableRequest(BaseModel):
    paid_provider: str = Field(
        default="groq",
        min_length=1,
        max_length=50,
    )

    daily_budget: float = Field(
        default=0.0,
        ge=0.0,
    )

    monthly_budget: float = Field(
        default=0.0,
        ge=0.0,
    )


class AIBillingProviderRequest(BaseModel):
    paid_provider: str = Field(
        min_length=1,
        max_length=50,
    )


class AIBillingBudgetRequest(BaseModel):
    daily_budget: float | None = Field(
        default=None,
        ge=0.0,
    )

    monthly_budget: float | None = Field(
        default=None,
        ge=0.0,
    )


class AIBillingStateResponse(BaseModel):
    paid_enabled: bool
    mode: str
    paid_provider: str

    daily_budget: float
    monthly_budget: float

    daily_spent: float
    monthly_spent: float

    updated_by: str | None


class AIBillingAuditLogResponse(BaseModel):
    id: str
    action: str

    previous_mode: str | None
    new_mode: str

    paid_enabled: bool
    paid_provider: str

    daily_budget: float
    monthly_budget: float

    admin_id: str | None
    details: str | None
    created_at: str
