"""
State SQLAlchemy Model.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import Boolean
from sqlalchemy import ForeignKey
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
    from app.modules.city.model import City


class State(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    """
    State / Province master data.
    """

    __tablename__ = "states"

    __table_args__ = (
        UniqueConstraint(
            "country_id",
            "name",
            name="uq_states_country_name",
        ),
        UniqueConstraint(
            "country_id",
            "code",
            name="uq_states_country_code",
        ),
    )

    # ==========================================================
    # Country
    # ==========================================================

    country_id: Mapped[str] = mapped_column(
        ForeignKey("countries.id"),
        nullable=False,
        index=True,
    )

    country: Mapped["Country"] = relationship(
        "Country",
        back_populates="states",
    )

    cities: Mapped[list["City"]] = relationship(
    "City",
    back_populates="state",
    cascade="all, delete-orphan",
)

    # ==========================================================
    # Basic Information
    # ==========================================================

    name: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
        index=True,
    )

    code: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
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
            f"<State("
            f"id={self.id}, "
            f"name='{self.name}', "
            f"code='{self.code}'"
            f")>"
        )