"""
Category SQLAlchemy Model.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import Boolean
from sqlalchemy import ForeignKey
from sqlalchemy import Integer
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
    from app.modules.category.model import Category


class Category(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    """
    Category model.

    Supports hierarchical categories.
    """

    __tablename__ = "categories"

    # ==========================================================
    # Basic Information
    # ==========================================================

    name: Mapped[str] = mapped_column(
        String(150),
        unique=True,
        nullable=False,
        index=True,
    )

    slug: Mapped[str] = mapped_column(
        String(180),
        unique=True,
        nullable=False,
        index=True,
    )

    description: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    icon: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    image_url: Mapped[str | None] = mapped_column(
        String(1000),
        nullable=True,
    )

    # ==========================================================
    # Hierarchy
    # ==========================================================

    parent_id: Mapped[str | None] = mapped_column(
        ForeignKey("categories.id"),
        nullable=True,
        index=True,
    )

    parent: Mapped["Category | None"] = relationship(
        "Category",
        remote_side="Category.id",
        back_populates="children",
    )

    children: Mapped[list["Category"]] = relationship(
        "Category",
        back_populates="parent",
    )

    # ==========================================================
    # Display
    # ==========================================================

    display_order: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False,
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
            f"<Category("
            f"id={self.id}, "
            f"name='{self.name}'"
            f")>"
        )