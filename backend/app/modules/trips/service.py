"""
Trip business logic.
"""

from __future__ import annotations

from datetime import date

from sqlalchemy.ext.asyncio import AsyncSession

from app.common.constants.not_found import NotFoundException
from app.modules.trips.model import Trip
from app.modules.trips.repository import TripRepository
from app.modules.trips.schema import TripCreate
from app.modules.trips.schema import TripUpdate


class TripService:
    """
    Business logic for user trips.
    """

    def __init__(self) -> None:
        self.repository = TripRepository()

    # ==========================================================
    # Create
    # ==========================================================

    async def create(
        self,
        db: AsyncSession,
        user_id: str,
        payload: TripCreate,
    ) -> Trip:

        self._validate_dates(
            payload.start_date,
            payload.end_date,
        )

        trip = Trip(
            user_id=user_id,
            **payload.model_dump(),
        )

        return await self.repository.create(
            db,
            trip,
        )

    # ==========================================================
    # Get
    # ==========================================================

    async def get_by_id(
        self,
        db: AsyncSession,
        user_id: str,
        trip_id: str,
    ) -> Trip:

        trip = await self.repository.get_by_id(
            db,
            trip_id,
            user_id,
        )

        if trip is None:
            raise NotFoundException(
                "Trip not found.",
            )

        return trip

    # ==========================================================
    # List
    # ==========================================================

    async def get_trips(
        self,
        db: AsyncSession,
        user_id: str,
        *,
        page: int = 1,
        size: int = 20,
        status: str | None = None,
    ) -> tuple[list[Trip], int]:

        return await self.repository.get_user_trips(
            db,
            user_id,
            page=page,
            size=size,
            status=status,
        )

    # ==========================================================
    # Upcoming
    # ==========================================================

    async def get_upcoming(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> list[Trip]:

        return await self.repository.get_upcoming(
            db,
            user_id,
        )

    # ==========================================================
    # Past
    # ==========================================================

    async def get_past(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> list[Trip]:

        return await self.repository.get_past(
            db,
            user_id,
        )

    # ==========================================================
    # Update
    # ==========================================================

    async def update(
        self,
        db: AsyncSession,
        user_id: str,
        trip_id: str,
        payload: TripUpdate,
    ) -> Trip:

        trip = await self.get_by_id(
            db,
            user_id,
            trip_id,
        )

        values = payload.model_dump(
            exclude_unset=True,
        )

        start_date = values.get(
            "start_date",
            trip.start_date,
        )

        end_date = values.get(
            "end_date",
            trip.end_date,
        )

        self._validate_dates(
            start_date,
            end_date,
        )

        return await self.repository.update(
            db,
            trip,
            values,
        )

    # ==========================================================
    # Delete
    # ==========================================================

    async def delete(
        self,
        db: AsyncSession,
        user_id: str,
        trip_id: str,
    ) -> None:

        trip = await self.get_by_id(
            db,
            user_id,
            trip_id,
        )

        await self.repository.delete(
            db,
            trip,
        )

    # ==========================================================
    # Validation
    # ==========================================================

    @staticmethod
    def _validate_dates(
        start_date: date,
        end_date: date,
    ) -> None:

        if end_date < start_date:
            raise ValueError(
                "End date cannot be before start date.",
            )
