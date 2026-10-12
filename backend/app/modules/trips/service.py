"""
Trip business logic.
"""

from __future__ import annotations

from datetime import date
from fastapi import HTTPException

from sqlalchemy.ext.asyncio import AsyncSession

from app.common.constants.not_found import NotFoundException
from app.modules.trips.model import Trip
from app.modules.trips.repository import TripRepository
from app.modules.trips.schema import TripCreate
from app.modules.trips.schema import TripUpdate
from app.modules.city.model import City
from app.modules.destination.model import Destination
from app.modules.planner.model import Planner


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

        values = payload.model_dump()
        values['city_id'] = await self._validate_location(db, values.get('destination_id'), values.get('city_id'))
        await self._validate_planner(db, user_id, values.get('planner_id'))
        trip = Trip(
            user_id=user_id,
            **values,
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
        if any(values.get(field) is None for field in ('title', 'start_date', 'end_date', 'travelers', 'budget_currency', 'status') if field in values):
            raise HTTPException(422, 'Required trip fields cannot be empty.')

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

        if 'city_id' in values or 'destination_id' in values:
            destination_id = values.get('destination_id', trip.destination_id)
            if 'city_id' in values and 'destination_id' not in values and values['city_id'] != trip.city_id:
                destination_id = None
            values['destination_id'] = destination_id
            city_id = values.get('city_id', None if 'destination_id' in values else trip.city_id)
            values['city_id'] = await self._validate_location(db, destination_id, city_id)
        if 'planner_id' in values:
            await self._validate_planner(db, user_id, values['planner_id'])
        if values.get('status') is not None and values['status'] not in {'draft', 'planned', 'ongoing', 'completed', 'cancelled'}:
            raise HTTPException(422, 'Choose a valid trip status.')

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

        if start_date is None or end_date is None or end_date < start_date:
            raise HTTPException(422, 'End date must be on or after the start date.')

    @staticmethod
    async def _validate_location(db, destination_id, city_id):
        if destination_id:
            destination = await db.get(Destination, destination_id)
            if destination is None or destination.is_deleted or not destination.is_active:
                raise HTTPException(404, 'Destination unavailable.')
            if city_id and city_id != destination.city_id:
                raise HTTPException(422, 'Destination and city do not match.')
            city_id = destination.city_id
        city = await db.get(City, city_id) if city_id else None
        if city is None or city.is_deleted or not city.is_active:
            raise HTTPException(404, 'City unavailable. Choose another city.')
        return city_id

    @staticmethod
    async def _validate_planner(db, user_id, planner_id):
        if planner_id:
            planner = await db.get(Planner, planner_id)
            if planner is None or planner.user_id != user_id or planner.is_deleted:
                raise HTTPException(404, 'Planner unavailable.')
