"""
Itinerary SQLAlchemy Models.

Trip
 └── ItineraryDay
       └── ItineraryItem
"""

from __future__ import annotations

from datetime import date
from datetime import time
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Date
from sqlalchemy import ForeignKey
from sqlalchemy import Integer
from sqlalchemy import Numeric
from sqlalchemy import String
from sqlalchemy import Text
from sqlalchemy import Time
from sqlalchemy.orm import Mapped
from sqlalchemy.orm import mapped_column
from sqlalchemy.orm import relationship

from app.database.base import (
    Base,
    TimestampMixin,
    UUIDMixin,
)

if TYPE_CHECKING:
    from app.modules.place.model import Place
    from app.modules.trips.model import Trip


# ==========================================================
# Itinerary Day
# ==========================================================

class ItineraryDay(
    Base,
    UUIDMixin,
    TimestampMixin,
):
    """
    One day inside a Trip itinerary.
    """

    __tablename__ = "itinerary_days"

    trip_id: Mapped[str] = mapped_column(
        ForeignKey("trips.id"),
        nullable=False,
        index=True,
    )

    day_number: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )

    title: Mapped[str | None] = mapped_column(
        String(200),
        nullable=True,
    )

    notes: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    trip: Mapped["Trip"] = relationship(
        "Trip",
    )

    items: Mapped[list["ItineraryItem"]] = relationship(
        "ItineraryItem",
        back_populates="itinerary_day",
        cascade="all, delete-orphan",
        order_by="ItineraryItem.sequence",
    )

    def __repr__(self) -> str:
        return (
            f"<ItineraryDay("
            f"id={self.id}, "
            f"trip_id={self.trip_id}, "
            f"day_number={self.day_number}"
            f")>"
        )


# ==========================================================
# Itinerary Item
# ==========================================================

class ItineraryItem(
    Base,
    UUIDMixin,
    TimestampMixin,
):
    """
    One activity, place, travel segment, or event
    inside an itinerary day.
    """

    __tablename__ = "itinerary_items"

    # ==========================================================
    # Parent Day
    # ==========================================================

    itinerary_day_id: Mapped[str] = mapped_column(
        ForeignKey("itinerary_days.id"),
        nullable=False,
        index=True,
    )

    itinerary_day: Mapped["ItineraryDay"] = relationship(
        "ItineraryDay",
        back_populates="items",
    )

    # ==========================================================
    # Optional Place
    # ==========================================================

    place_id: Mapped[str | None] = mapped_column(
        ForeignKey("places.id"),
        nullable=True,
        index=True,
    )

    place: Mapped["Place | None"] = relationship(
        "Place",
    )

    # ==========================================================
    # Basic Information
    # ==========================================================

    title: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
    )

    description: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    # ==========================================================
    # Activity
    # ==========================================================

    activity_type: Mapped[str] = mapped_column(
        String(80),
        nullable=False,
        default="activity",
        server_default="activity",
    )

    # ==========================================================
    # Timing
    # ==========================================================

    start_time: Mapped[time | None] = mapped_column(
        Time,
        nullable=True,
    )

    end_time: Mapped[time | None] = mapped_column(
        Time,
        nullable=True,
    )

    estimated_duration_minutes: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    # ==========================================================
    # Ordering
    # ==========================================================

    sequence: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=1,
        server_default="1",
    )

    # ==========================================================
    # Transportation
    # ==========================================================

    transport_mode: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )

    # ==========================================================
    # Coordinates
    # ==========================================================

    latitude: Mapped[Decimal | None] = mapped_column(
        Numeric(10, 6),
        nullable=True,
    )

    longitude: Mapped[Decimal | None] = mapped_column(
        Numeric(10, 6),
        nullable=True,
    )

    # ==========================================================
    # Notes
    # ==========================================================

    notes: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    def __repr__(self) -> str:
        return (
            f"<ItineraryItem("
            f"id={self.id}, "
            f"title='{self.title}', "
            f"sequence={self.sequence}"
            f")>"
        )
