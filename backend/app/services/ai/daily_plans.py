"""Per-account UTC daily limit shared by conversational and structured plans."""
from datetime import date, datetime, timedelta, timezone
from fastapi import HTTPException
from sqlalchemy import Date, Integer, String, delete, select
from sqlalchemy.orm import Mapped, mapped_column
from app.database.base import Base

LIMIT = 5

class DailyPlanUsage(Base):
    __tablename__ = 'ai_daily_plan_usage'
    user_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    day: Mapped[date] = mapped_column(Date, primary_key=True)
    used: Mapped[int] = mapped_column(Integer, nullable=False, default=0)


def current_day():
    return datetime.now(timezone.utc).date()


def limit_error():
    return HTTPException(429, 'You have used your 5 AI plans for today. Your allowance resets at 00:00 UTC. You can still browse places and manage saved trips.')


async def status(db, user_id):
    day = current_day()
    used = await db.scalar(select(DailyPlanUsage.used).where(
        DailyPlanUsage.user_id == user_id, DailyPlanUsage.day == day)) or 0
    reset = datetime.combine(day + timedelta(days=1), datetime.min.time(), tzinfo=timezone.utc)
    return {'limit': LIMIT, 'used': used, 'remaining': max(0, LIMIT-used), 'resets_at': reset.isoformat()}


async def check(db, user_id):
    if (await status(db, user_id))['remaining'] == 0:
        raise limit_error()


async def consume(db, user_id):
    """Atomically claim a completed plan in the caller's save transaction.

    Racing provider requests may finish together, but only five can be persisted
    or returned. Provider failures and clarification replies never call this.
    """
    from sqlalchemy.dialects.postgresql import insert as pg_insert
    from sqlalchemy.dialects.sqlite import insert as sqlite_insert
    day = current_day()
    insert = pg_insert if db.bind.dialect.name == 'postgresql' else sqlite_insert
    stmt = insert(DailyPlanUsage).values(user_id=user_id, day=day, used=1)
    stmt = stmt.on_conflict_do_update(index_elements=['user_id', 'day'],
        set_={'used': DailyPlanUsage.used + 1}, where=DailyPlanUsage.used < LIMIT).returning(DailyPlanUsage.used)
    if (await db.execute(stmt)).scalar_one_or_none() is None:
        raise limit_error()
    await db.execute(delete(DailyPlanUsage).where(DailyPlanUsage.day < day - timedelta(days=2)))
