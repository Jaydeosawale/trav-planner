"""
User travel profile and behavior models.
"""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean
from sqlalchemy import DateTime
from sqlalchemy import ForeignKey
from sqlalchemy import String
from sqlalchemy import Text
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
    from app.modules.auth.model import User
    from app.modules.place.model import Place


# ==========================================================
# Travel Profile
# ==========================================================

class UserTravelProfile(
    Base,
    UUIDMixin,
    TimestampMixin,
):
    """
    Stable travel preferences of a user.
    """

    __tablename__ = "user_travel_profiles"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
        unique=True,
        index=True,
    )

    travel_style: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    budget_level: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )

    preferred_transport: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    accommodation_preference: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    food_preference: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    interests: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    other_preferences: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    user: Mapped["User"] = relationship(
        "User",
    )


# ==========================================================
# Search History
# ==========================================================

class UserSearchHistory(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    """
    User search activity.

    Used later by recommendation and AI personalization.
    """

    __tablename__ = "user_search_history"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    query: Mapped[str] = mapped_column(
        String(500),
        nullable=False,
    )

    search_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="place",
    )

    filters_text: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    user: Mapped["User"] = relationship(
        "User",
    )


# ==========================================================
# Place Likes
# ==========================================================

class UserPlaceLike(
    Base,
    UUIDMixin,
    TimestampMixin,
):
    """
    Places explicitly liked by a user.
    """

    __tablename__ = "user_place_likes"

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "place_id",
            name="uq_user_place_like",
        ),
    )

    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    place_id: Mapped[str] = mapped_column(
        ForeignKey("places.id"),
        nullable=False,
        index=True,
    )

    user: Mapped["User"] = relationship(
        "User",
    )

    place: Mapped["Place"] = relationship(
        "Place",
    )


# ==========================================================
# Place Saves
# ==========================================================

class UserPlaceSave(
    Base,
    UUIDMixin,
    TimestampMixin,
):
    """
    Places saved/bookmarked by a user.
    """

    __tablename__ = "user_place_saves"

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "place_id",
            name="uq_user_place_save",
        ),
    )

    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    place_id: Mapped[str] = mapped_column(
        ForeignKey("places.id"),
        nullable=False,
        index=True,
    )

    user: Mapped["User"] = relationship(
        "User",
    )

    place: Mapped["Place"] = relationship(
        "Place",
    )


# ==========================================================
# Place Views
# ==========================================================

class UserPlaceView(
    Base,
    UUIDMixin,
):
    """
    Records a user's place views.

    Multiple views are allowed.
    """

    __tablename__ = "user_place_views"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    place_id: Mapped[str] = mapped_column(
        ForeignKey("places.id"),
        nullable=False,
        index=True,
    )

    viewed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    user: Mapped["User"] = relationship(
        "User",
    )

    place: Mapped["Place"] = relationship(
        "Place",
    )