"""
Country SQLAlchemy Model.
"""

from __future__ import annotations

from decimal import Decimal

from sqlalchemy import Boolean
from sqlalchemy import Numeric
from sqlalchemy import String
from sqlalchemy.orm import Mapped
from sqlalchemy.orm import mapped_column
from typing import TYPE_CHECKING
from sqlalchemy.orm import relationship

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.modules.state.model import State
    from app.modules.city.model import City

from app.database.base import (
    Base,
    SoftDeleteMixin,
    TimestampMixin,
    UUIDMixin,
)


class Country(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    """
    Country master data.
    """

    __tablename__ = "countries"

    # ==========================================================
    # Basic Information
    # ==========================================================

    name: Mapped[str] = mapped_column(
        String(150),
        unique=True,
        nullable=False,
        index=True,
    )

    iso2: Mapped[str] = mapped_column(
        String(2),
        unique=True,
        nullable=False,
        index=True,
    )

    iso3: Mapped[str] = mapped_column(
        String(3),
        unique=True,
        nullable=False,
        index=True,
    )

    # ==========================================================
    # Relationships
    # ==========================================================

    states: Mapped[list["State"]] = relationship(
       "State",
       back_populates="country",

       cascade="all, delete-orphan",)

    cities: Mapped[list["City"]] = relationship(
       "City",
      back_populates="country",
      )

    # ==========================================================
    # Contact
    # ==========================================================

    phone_code: Mapped[str] = mapped_column(
        String(10),
        nullable=False,
    )

    # ==========================================================
    # Currency
    # ==========================================================

    currency_code: Mapped[str] = mapped_column(
        String(10),
        nullable=False,
    )

    currency_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    # ==========================================================
    # Geography
    # ==========================================================

    capital: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
    )

    continent: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    timezone: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    flag_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    latitude: Mapped[Decimal | None] = mapped_column(
        Numeric(10, 6),
        nullable=True,
    )

    longitude: Mapped[Decimal | None] = mapped_column(
        Numeric(10, 6),
        nullable=True,
    )

    # ==========================================================
    # Status
    # ==========================================================

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
            f"<Country("
            f"id={self.id}, "
            f"name='{self.name}', "
            f"iso2='{self.iso2}'"
            f")>"
        )