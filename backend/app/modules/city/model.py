"""
City SQLAlchemy Model.
"""

from __future__ import annotations

from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Boolean
from sqlalchemy import ForeignKey
from sqlalchemy import Numeric
from sqlalchemy import String
from sqlalchemy import UniqueConstraint
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
    from app.modules.country.model import Country
    from app.modules.state.model import State


class City(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    """
    City master data.
    """

    __tablename__ = "cities"

    __table_args__ = (
        UniqueConstraint(
            "state_id",
            "name",
            name="uq_cities_state_name",
        ),
    )

    # ==========================================================
    # Relationships
    # ==========================================================

    country_id: Mapped[str] = mapped_column(
        ForeignKey("countries.id"),
        nullable=False,
        index=True,
    )

    state_id: Mapped[str] = mapped_column(
        ForeignKey("states.id"),
        nullable=False,
        index=True,
    )

    country: Mapped["Country"] = relationship(
        "Country",
        back_populates="cities",
    )

    state: Mapped["State"] = relationship(
        "State",
        back_populates="cities",
    )

    # ==========================================================
    # Basic Information
    # ==========================================================

    name: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
        index=True,
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

    def __repr__(self) -> str:
        return (
            f"<City("
            f"id={self.id}, "
            f"name='{self.name}'"
            f")>"
        )