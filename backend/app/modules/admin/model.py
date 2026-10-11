from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import (
    Base,
    TimestampMixin,
    UUIDMixin,
)


class AIBillingSettings(
    UUIDMixin,
    TimestampMixin,
    Base,
):
    """
    Persistent Admin-controlled AI billing configuration.

    There should normally be one active settings record.
    """

    __tablename__ = "ai_billing_settings"

    paid_enabled: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    billing_mode: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="free_only",
    )

    paid_provider: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="groq",
    )

    daily_budget: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    monthly_budget: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    daily_spent: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    monthly_spent: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    updated_by: Mapped[str | None] = mapped_column(
        String(36),
        nullable=True,
    )


class AIBillingAuditLog(
    UUIDMixin,
    Base,
):
    """
    Immutable audit record for Admin AI billing actions.
    """

    __tablename__ = "ai_billing_audit_logs"

    action: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )

    previous_mode: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )

    new_mode: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
    )

    paid_enabled: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
    )

    paid_provider: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )

    daily_budget: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    monthly_budget: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    admin_id: Mapped[str | None] = mapped_column(
        String(36),
        nullable=True,
    )

    details: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )