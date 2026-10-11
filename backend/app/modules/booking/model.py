"""
Booking SQLAlchemy Model.

A Booking represents a reservation associated with a user's Trip.

Examples:
- Train
- Hotel
- Flight
- Bus
- Activity
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import DateTime
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
    from app.modules.trips.model import Trip
    from app.modules.itinerary.model import ItineraryItem


class Booking(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    """
    Reservation belonging to a user's trip.
    """

    __tablename__ = "bookings"

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
    # Trip
    # ==========================================================

    trip_id: Mapped[str] = mapped_column(
        ForeignKey("trips.id"),
        nullable=False,
        index=True,
    )

    trip: Mapped["Trip"] = relationship(
        "Trip",
    )

    # ==========================================================
    # Optional Itinerary Item
    # ==========================================================

    itinerary_item_id: Mapped[str | None] = mapped_column(
        ForeignKey("itinerary_items.id"),
        nullable=True,
        index=True,
    )

    itinerary_item: Mapped["ItineraryItem | None"] = relationship(
        "ItineraryItem",
    )

    # ==========================================================
    # Booking Type
    # ==========================================================

    booking_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True,
    )

    # ==========================================================
    # Provider
    # ==========================================================

    provider: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    external_booking_id: Mapped[str | None] = mapped_column(
        String(200),
        nullable=True,
        index=True,
    )

    # ==========================================================
    # Booking Information
    # ==========================================================

    title: Mapped[str] = mapped_column(
        String(250),
        nullable=False,
    )

    confirmation_code: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True,
    )

    # ==========================================================
    # Status
    # ==========================================================

    status: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="pending",
        server_default="pending",
        index=True,
    )

    # ==========================================================
    # Dates
    # ==========================================================

    booking_date: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    start_datetime: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    end_datetime: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    # ==========================================================
    # Passenger / Guest Count
    # ==========================================================

    passenger_count: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=1,
        server_default="1",
    )

    # ==========================================================
    # Amount
    # ==========================================================

    amount: Mapped[Decimal | None] = mapped_column(
        Numeric(12, 2),
        nullable=True,
    )

    currency: Mapped[str] = mapped_column(
        String(3),
        nullable=False,
        default="INR",
        server_default="INR",
    )

    # ==========================================================
    # Provider / Booking Details
    # ==========================================================

    details: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    # ==========================================================
    # Representation
    # ==========================================================

    def __repr__(self) -> str:
        return (
            f"<Booking("
            f"id={self.id}, "
            f"type='{self.booking_type}', "
            f"title='{self.title}', "
            f"status='{self.status}'"
            f")>"
        )
