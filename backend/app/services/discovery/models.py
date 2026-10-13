from datetime import datetime
from sqlalchemy import String, Text, DateTime, Integer
from sqlalchemy.orm import Mapped, mapped_column
from app.database.base import Base


class DiscoveryCache(Base):
    __tablename__ = "discovery_cache"
    key: Mapped[str] = mapped_column(String(120), primary_key=True)
    kind: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    city_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    value: Mapped[str] = mapped_column(Text, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )


class DiscoveryBudget(Base):
    __tablename__ = "discovery_budget"
    day: Mapped[str] = mapped_column(String(10), primary_key=True)
    calls: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
