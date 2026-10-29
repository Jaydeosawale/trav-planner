"""User-submitted AI safety reports, retained separately for developer review."""
from sqlalchemy import String, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.database.base import Base, UUIDMixin, TimestampMixin


class AIContentReport(Base, UUIDMixin, TimestampMixin):
    __tablename__ = 'ai_content_reports'
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    source_kind: Mapped[str] = mapped_column(String(20))
    reference_id: Mapped[str] = mapped_column(String(36))
    reason: Mapped[str] = mapped_column(String(40))
    details: Mapped[str] = mapped_column(Text, default='')
    content_excerpt: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default='pending')
