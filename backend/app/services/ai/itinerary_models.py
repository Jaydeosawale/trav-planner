from datetime import datetime
from sqlalchemy import DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.database.base import Base, UUIDMixin, TimestampMixin


class ItineraryDraft(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "ai_itinerary_drafts"
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    city_id: Mapped[str] = mapped_column(String(36))
    content_json: Mapped[str] = mapped_column(Text)
    trip_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
