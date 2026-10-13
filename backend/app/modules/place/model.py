"""
Place SQLAlchemy Model.

Represents points of interest such as cafes, restaurants,
hotels, attractions, activities and other useful travel places.
"""

from __future__ import annotations

from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Boolean
from sqlalchemy import ForeignKey
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
    from app.modules.city.model import City
    from app.modules.category.model import Category


class Place(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    """
    Travel place / point of interest.

    Examples:
        Cafe
        Restaurant
        Hotel
        Attraction
        Activity
        Shopping
        Museum
        Park
        Beach
        Viewpoint
    """

    __tablename__ = "places"

    # ==========================================================
    # Location
    # ==========================================================

    city_id: Mapped[str] = mapped_column(
        ForeignKey("cities.id"),
        nullable=False,
        index=True,
    )

    city: Mapped["City"] = relationship(
        "City",
    )

    # ==========================================================
    # Category
    # ==========================================================

    category_id: Mapped[str | None] = mapped_column(
        ForeignKey("categories.id"),
        nullable=True,
        index=True,
    )

    category: Mapped["Category | None"] = relationship(
        "Category",
    )

    # ==========================================================
    # Basic Information
    # ==========================================================

    name: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
        index=True,
    )

    slug: Mapped[str] = mapped_column(
        String(220),
        nullable=False,
        unique=True,
        index=True,
    )

    place_type: Mapped[str] = mapped_column(
        String(80),
        nullable=False,
        index=True,
    )

    short_description: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    description: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    # ==========================================================
    # Address
    # ==========================================================

    address: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    locality: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True,
        index=True,
    )

    postal_code: Mapped[str | None] = mapped_column(
        String(30),
        nullable=True,
    )

    # ==========================================================
    # Geography
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
    # Media
    # ==========================================================

    image_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    # ==========================================================
    # External Provider
    # ==========================================================

    image_credit: Mapped[str | None] = mapped_column(Text, nullable=True)
    visiting_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    content_revision: Mapped[str | None] = mapped_column(String(30), nullable=True)

    provider: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
        index=True,
    )

    external_place_id: Mapped[str | None] = mapped_column(
        String(200),
        nullable=True,
        index=True,
    )

    # ==========================================================
    # Discovery
    # ==========================================================

    rating: Mapped[Decimal | None] = mapped_column(
        Numeric(3, 2),
        nullable=True,
    )

    price_level: Mapped[int | None] = mapped_column(
        nullable=True,
    )

    is_featured: Mapped[bool] = mapped_column(
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
            f"<Place("
            f"id={self.id}, "
            f"name='{self.name}', "
            f"place_type='{self.place_type}'"
            f")>"
        )