
"""
Trip repository.
"""

from __future__ import annotations

from datetime import date

from sqlalchemy import func
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.trips.model import Trip


class TripRepository:
    """
    Database operations for trips.
    """

    async def update(self, db: AsyncSession, trip: Trip, values: dict) -> Trip:
        for field, value in values.items():
            setattr(trip, field, value)
        await db.commit()
        await db.refresh(trip)
        return trip

    async def delete(self, db: AsyncSession, trip: Trip) -> None:
        trip.is_deleted = True
        trip.deleted_at = func.now()
        await db.commit()

    # ==========================================================
    # Create
    # ==========================================================

    async def create(
        self,
        db: AsyncSession,
        trip: Trip,
    ) -> Trip:
        db.add(trip)

        await db.commit()
        await db.refresh(trip)

        return trip

    # ==========================================================
    # Get By ID
    # ==========================================================

    async def get_by_id(
        self,
        db: AsyncSession,
        trip_id: str,
        user_id: str,
    ) -> Trip | None:
        result = await db.execute(
            select(Trip).where(
                Trip.id == trip_id,
                Trip.user_id == user_id,
                Trip.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none()

    # ==========================================================
    # List User Trips
    # ==========================================================

    async def get_user_trips(
        self,
        db: AsyncSession,
        user_id: str,
        *,
        page: int = 1,
        size: int = 20,
        status: str | None = None,
    ) -> tuple[list[Trip], int]:

        filters = [
            Trip.user_id == user_id,
            Trip.is_deleted.is_(False),
        ]

        if status:
            filters.append(
                Trip.status == status,
            )

        count_result = await db.execute(
            select(func.count())
            .select_from(Trip)
            .where(*filters)
        )

        total = count_result.scalar_one()

        offset = (page - 1) * size

        result = await db.execute(
            select(Trip)
            .where(*filters)
            .order_by(
                Trip.start_date.desc(),
                Trip.created_at.desc(),
            )
            .offset(offset)
            .limit(size)
        )

        trips = list(
            result.scalars().all()
        )

        return trips, total

    # ==========================================================
    # Upcoming Trips
    # ==========================================================

    async def get_upcoming(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> list[Trip]:

        today = date.today()

        result = await db.execute(
            select(Trip)
            .where(
                Trip.user_id == user_id,
                Trip.is_deleted.is_(False),
                Trip.end_date >= today,
                Trip.status.notin_(
                    ["cancelled", "completed"],
                ),
            )
            .order_by(
                Trip.start_date.asc(),
            )
        )

        return list(
            result.scalars().all()
        )

    # ==========================================================
    # Past Trips
    # ==========================================================

    async def get_past(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> list[Trip]:

        today = date.today()

        result = await db.execute(
            select(Trip)
            .where(
                Trip.user_id == user_id,
                Trip.is_deleted.is_(False),
                Trip.end_date < today,
            )
            .order_by(
                Trip.start_date.desc(),
            )
        )

        return list(
            result.scalars().all()
        )
