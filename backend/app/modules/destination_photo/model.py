"""
Destination Photo SQLAlchemy Model.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import Boolean
from sqlalchemy import ForeignKey
from sqlalchemy import Integer
from sqlalchemy import String
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
    from app.modules.destination.model import Destination


class DestinationPhoto(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    """
    Photo belonging to a travel destination.

    Photos are kept separately from the destination so a
    destination can have an unlimited gallery.
    """

    __tablename__ = "destination_photos"

    # ==========================================================
    # Destination
    # ==========================================================

    destination_id: Mapped[str] = mapped_column(
        ForeignKey(
            "destinations.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    destination: Mapped["Destination"] = relationship(
        "Destination",
        back_populates="photos",
    )

    # ==========================================================
    # Media
    # ==========================================================

    image_url: Mapped[str] = mapped_column(
        String(1000),
        nullable=False,
    )

    caption: Mapped[str | None] = mapped_column(
        String(300),
        nullable=True,
    )

    # ==========================================================
    # Display
    # ==========================================================

    display_order: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False,
    )

    is_cover: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
    )

    # ==========================================================
    # Representation
    # ==========================================================

    def __repr__(self) -> str:
        return (
            f"<DestinationPhoto("
            f"id={self.id}, "
            f"destination_id={self.destination_id}, "
            f"is_cover={self.is_cover}"
            f")>"
        )