"""
Planner SQLAlchemy Model.
"""

from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Date
from sqlalchemy import ForeignKey
from sqlalchemy import Integer
from sqlalchemy import Numeric
from sqlalchemy import String
from sqlalchemy import Text
from sqlalchemy.orm import Mapped
from sqlalchemy.orm import mapped_column
from sqlalchemy.orm import relationship

from app.database.base import (
    Base,
    SoftDeleteMixin,
    TimestampMixin,
    UUIDMixin,
)

if TYPE_CHECKING:
    from app.modules.auth.model import User
    from app.modules.destination.model import Destination


class Planner(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    """
    Travel planning request.

    Represents the user's travel requirements that can later
    be processed by the AI planning system.
    """

    __tablename__ = "planners"

    # ==========================================================
    # Ownership
    # ==========================================================

    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    user: Mapped["User"] = relationship(
        "User",
    )

    # ==========================================================
    # Destination
    # ==========================================================

    destination_id: Mapped[str] = mapped_column(
        ForeignKey("destinations.id"),
        nullable=False,
        index=True,
    )

    destination: Mapped["Destination"] = relationship(
        "Destination",
    )

    # ==========================================================
    # Basic Information
    # ==========================================================

    title: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
    )

    # ==========================================================
    # Travel Dates
    # ==========================================================

    start_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )

    end_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )

    # ==========================================================
    # Travelers
    # ==========================================================

    travelers: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=1,
    )

    # ==========================================================
    # Budget
    # ==========================================================

    budget_amount: Mapped[Decimal | None] = mapped_column(
        Numeric(12, 2),
        nullable=True,
    )

    budget_currency: Mapped[str] = mapped_column(
        String(3),
        nullable=False,
        default="INR",
    )

    # ==========================================================
    # Travel Preferences
    # ==========================================================

    travel_style: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    preferences: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    # ==========================================================
    # Planning Status
    # ==========================================================

    status: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="draft",
        index=True,
    )

    # ==========================================================
    # Representation
    # ==========================================================

    def __repr__(self) -> str:
        return (
            f"<Planner("
            f"id={self.id}, "
            f"title='{self.title}', "
            f"status='{self.status}'"
            f")>"
        )