"""Persistent provider order with a deployment-level zero-cost gate."""

import json
from datetime import datetime, timezone
from pydantic import BaseModel, Field, model_validator
from sqlalchemy import Integer, Boolean, Text, String
from sqlalchemy.orm import Mapped, mapped_column
from app.database.base import Base
from app.core.settings import get_settings

PROVIDERS = ("openai", "groq", "gemini")


class AIRoutingSettings(Base):
    __tablename__ = "ai_routing_settings"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    provider_order: Mapped[str] = mapped_column(
        Text, default='["openai","groq","gemini"]'
    )
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    updated_by: Mapped[str | None] = mapped_column(String(36), nullable=True)


class RoutingUpdate(BaseModel):
    provider_order: list[str] = Field(min_length=0, max_length=3)
    enabled: bool = True

    @model_validator(mode="after")
    def validate_order(self):
        if len(set(self.provider_order)) != len(self.provider_order) or any(
            p not in PROVIDERS for p in self.provider_order
        ):
            raise ValueError("Choose each supported provider at most once.")
        return self


async def load_routing(db):
    row = await db.get(AIRoutingSettings, 1)
    return (
        RoutingUpdate(
            provider_order=json.loads(row.provider_order), enabled=row.enabled
        )
        if row
        else RoutingUpdate(provider_order=list(PROVIDERS))
    )


def connection_status(settings=None):
    settings = settings or get_settings()
    # This switch is NEVER set by the browser UI. Activation requires verifying
    # an account with no chargeable fallback; a key alone proves no such thing.
    until = settings.OPENAI_FREE_ACCESS_UNTIL
    try:
        expires = (
            datetime.fromisoformat(until.replace("Z", "+00:00")) if until else None
        )
        credit_verified = bool(
            expires and expires.tzinfo and expires > datetime.now(timezone.utc)
        )
    except ValueError:
        credit_verified = False
    return {
        "openai": {
            "configured": bool(settings.OPENAI_API_KEY),
            "eligible": bool(settings.OPENAI_API_KEY) and credit_verified,
            "reason": (
                "Verified free access"
                if credit_verified
                else "Free access must be verified before activation"
            ),
        },
        "groq": {
            "configured": bool(settings.GROQ_API_KEY),
            "eligible": bool(settings.GROQ_API_KEY),
            "reason": "Free tier only",
        },
        "gemini": {
            "configured": bool(settings.GEMINI_API_KEY),
            "eligible": bool(settings.GEMINI_API_KEY),
            "reason": "Free tier only",
        },
    }


from app.database.base import UUIDMixin, TimestampMixin


class AIUsageRecord(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "ai_usage_records"
    provider: Mapped[str] = mapped_column(String(30))
    model: Mapped[str | None] = mapped_column(String(100), nullable=True)
    succeeded: Mapped[bool] = mapped_column(Boolean)
    input_tokens: Mapped[int | None] = mapped_column(Integer, nullable=True)
    output_tokens: Mapped[int | None] = mapped_column(Integer, nullable=True)
    total_tokens: Mapped[int | None] = mapped_column(Integer, nullable=True)
    error_category: Mapped[str | None] = mapped_column(String(30), nullable=True)
