"""
User / Authentication Model.
"""

from __future__ import annotations

from sqlalchemy import Boolean
from sqlalchemy import String
from sqlalchemy.orm import Mapped
from sqlalchemy.orm import mapped_column

from app.database.base import (
    Base,
    SoftDeleteMixin,
    TimestampMixin,
    UUIDMixin,
)


class User(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    """
    Application user.
    """

    __tablename__ = "users"

    # ==========================================================
    # Authentication
    # ==========================================================

    email: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        unique=True,
        index=True,
    )

    password_hash: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    # ==========================================================
    # Basic Information
    # ==========================================================

    full_name: Mapped[str] = mapped_column(
        String(150),
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
            f"<User("
            f"id={self.id}, "
            f"email='{self.email}', "
            f"full_name='{self.full_name}'"
            f")>"
        )