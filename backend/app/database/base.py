"""
SQLAlchemy Declarative Base.

Every database model should inherit from Base.

Example:

class Banner(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    ...
"""

from __future__ import annotations

from datetime import datetime
from uuid import uuid4

from sqlalchemy import (
    Boolean,
    DateTime,
    MetaData,
    String,
    text,
)
from sqlalchemy.orm import (
    DeclarativeBase,
    Mapped,
    mapped_column,
)

# ==========================================================
# Alembic Naming Convention
# ==========================================================

NAMING_CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}

metadata = MetaData(
    naming_convention=NAMING_CONVENTION,
)


# ==========================================================
# Declarative Base
# ==========================================================

class Base(DeclarativeBase):
    """
    Base class for all SQLAlchemy models.
    """

    metadata = metadata


# ==========================================================
# UUID Primary Key
# ==========================================================

class UUIDMixin:
    """
    Adds UUID primary key.
    """

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid4()),
    )


# ==========================================================
# Timestamp Columns
# ==========================================================

class TimestampMixin:
    """
    Automatically manages timestamps.
    """

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("(CURRENT_TIMESTAMP)"),
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("(CURRENT_TIMESTAMP)"),
        onupdate=text("(CURRENT_TIMESTAMP)"),
        nullable=False,
    )


# ==========================================================
# Soft Delete
# ==========================================================

class SoftDeleteMixin:
    """
    Soft delete support.

    Records are never physically deleted.
    """

    is_deleted: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )