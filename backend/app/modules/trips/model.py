"""
Trip SQLAlchemy Model.

A Trip represents a user's saved/planned travel journey.

Planner = planning workspace/request.
Trip = actual saved travel plan/history.
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
    from app.modules.planner.model import Planner


class Trip(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    """
    User travel journey.

    A Trip is created when a planning request becomes
    a real saved travel plan.

    It will later contain:
    - Itinerary
    - Routes
    - Transport
    - Bookings
    """

    __tablename__ = "trips"

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
    # Source Planner
    # ==========================================================

    planner_id: Mapped[str | None] = mapped_column(
        ForeignKey("planners.id"),
        nullable=True,
        index=True,
    )

    planner: Mapped["Planner | None"] = relationship(
        "Planner",
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
        server_default="INR",
    )

    # ==========================================================
    # Travel Preferences
    # ==========================================================

    travel_style: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    notes: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    # ==========================================================
    # Trip Status
    # ==========================================================

    status: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="planned",
        server_default="planned",
        index=True,
    )

    # ==========================================================
    # Representation
    # ==========================================================

    def __repr__(self) -> str:
        return (
            f"<Trip("
            f"id={self.id}, "
            f"title='{self.title}', "
            f"status='{self.status}'"
            f")>"
        )
