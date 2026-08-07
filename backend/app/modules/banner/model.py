from __future__ import annotations

from sqlalchemy import Boolean
from sqlalchemy import Integer
from sqlalchemy import String
from sqlalchemy.orm import Mapped
from sqlalchemy.orm import mapped_column

from app.database.base import Base
from app.database.base import SoftDeleteMixin
from app.database.base import TimestampMixin
from app.database.base import UUIDMixin


class Banner(
    Base,
    UUIDMixin,
    TimestampMixin,
    SoftDeleteMixin,
):
    """
    Home page promotional banner.
    """

    __tablename__ = "banners"

    title: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
    )

    subtitle: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    image_url: Mapped[str] = mapped_column(
        String(1000),
        nullable=False,
    )

    redirect_url: Mapped[str | None] = mapped_column(
        String(1000),
        nullable=True,
    )

    display_order: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False,
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
    )