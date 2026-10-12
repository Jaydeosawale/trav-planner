"""
Itinerary service.

Business logic for itinerary management.

Ownership flow:

Current User
    ↓
Trip
    ↓
Itinerary Day
    ↓
Itinerary Item
"""

from __future__ import annotations
from fastapi import HTTPException
from app.modules.place.model import Place

from sqlalchemy.ext.asyncio import AsyncSession

from app.common.exceptions.conflict import ConflictException
from app.common.constants.not_found import NotFoundException

from app.modules.itinerary.model import (
    ItineraryDay,
    ItineraryItem,
)
from app.modules.itinerary.repository import ItineraryRepository
from app.modules.itinerary.schema import (
    ItineraryDayCreate,
    ItineraryDayUpdate,
    ItineraryItemCreate,
    ItineraryItemUpdate,
)
from app.modules.trips.repository import TripRepository
from app.services.base import BaseService


class ItineraryService(BaseService[ItineraryDay]):
    """
    Itinerary business logic.
    """

    def __init__(self) -> None:
        super().__init__(
            ItineraryRepository(),
        )

        self.trip_repository = TripRepository()

    # ==========================================================
    # Ownership
    # ==========================================================

    async def _get_user_trip(
     self,
     db: AsyncSession,
      trip_id: str,
       user_id: str,
    ):
     """
    Get a trip owned by the current user.
    """

     trip = await self.trip_repository.get_by_id(
        db,
        trip_id,
        user_id,
    )

     if trip is None:
        raise NotFoundException(
            "Trip not found."
        )

     return trip

    async def _get_user_day(
        self,
        db: AsyncSession,
        day_id: str,
        user_id: str,
    ) -> ItineraryDay:
        """
        Get an itinerary day through its owned trip.
        """

        day = await self.repository.get_day_by_id(
            db,
            day_id,
        )

        if day is None:
            raise NotFoundException(
                "Itinerary day not found."
            )

        await self._get_user_trip(
            db,
            day.trip_id,
            user_id,
        )

        return day

    async def _get_user_item(
        self,
        db: AsyncSession,
        item_id: str,
        user_id: str,
    ) -> ItineraryItem:
        """
        Get an itinerary item through its day and owned trip.
        """

        item = await self.repository.get_item_by_id(
            db,
            item_id,
        )

        if item is None:
            raise NotFoundException(
                "Itinerary item not found."
            )

        day = await self._get_user_day(
            db,
            item.itinerary_day_id,
            user_id,
        )

        return item

    # ==========================================================
    # Get Complete Itinerary
    # ==========================================================

    async def get_itinerary(
        self,
        db: AsyncSession,
        trip_id: str,
        user_id: str,
    ) -> list[ItineraryDay]:
        """
        Get the complete itinerary for a user's trip.
        """

        await self._get_user_trip(
            db,
            trip_id,
            user_id,
        )

        return await self.repository.get_days_by_trip(
            db,
            trip_id,
        )

    # ==========================================================
    # Create Day
    # ==========================================================

    async def create_day(
        self,
        db: AsyncSession,
        trip_id: str,
        user_id: str,
        payload: ItineraryDayCreate,
    ) -> ItineraryDay:
        """
        Create a new itinerary day.
        """

        trip = await self._get_user_trip(
            db,
            trip_id,
            user_id,
        )

        if not trip.start_date <= payload.date <= trip.end_date:
            raise HTTPException(422, 'Choose a day inside the trip dates.')

        existing = (
            await self.repository.get_day_by_trip_and_number(
                db,
                trip_id,
                payload.day_number,
            )
        )

        if existing is not None:
            raise ConflictException(
                f"Day {payload.day_number} already exists "
                "for this trip."
            )

        day = ItineraryDay(
            trip_id=trip_id,
            **payload.model_dump(),
        )

        return await self.repository.create_day(
            db,
            day,
        )

    # ==========================================================
    # Update Day
    # ==========================================================

    async def update_day(
        self,
        db: AsyncSession,
        day_id: str,
        user_id: str,
        payload: ItineraryDayUpdate,
    ) -> ItineraryDay:
        """
        Update an itinerary day.
        """

        day = await self._get_user_day(
            db,
            day_id,
            user_id,
        )

        values = payload.model_dump(
            exclude_unset=True,
        )

        if 'day_number' in values and values['day_number'] is None:
            raise HTTPException(422, 'Day number cannot be empty.')
        trip = await self._get_user_trip(db, day.trip_id, user_id)
        selected_date = values.get('date', day.date)
        if selected_date is None or not trip.start_date <= selected_date <= trip.end_date:
            raise HTTPException(422, 'Choose a day inside the trip dates.')

        if (
            "day_number" in values
            and values["day_number"] != day.day_number
        ):
            existing = (
                await self.repository
                .get_day_by_trip_and_number(
                    db,
                    day.trip_id,
                    values["day_number"],
                )
            )

            if existing is not None:
                raise ConflictException(
                    f"Day {values['day_number']} already exists "
                    "for this trip."
                )

        return await self.repository.update_day(
            db,
            day,
            values,
        )

    # ==========================================================
    # Delete Day
    # ==========================================================

    async def delete_day(
        self,
        db: AsyncSession,
        day_id: str,
        user_id: str,
    ) -> None:
        """
        Delete an itinerary day.
        """

        await self._get_user_day(
            db,
            day_id,
            user_id,
        )

        await self.repository.delete_day(
            db,
            day_id,
        )

    # ==========================================================
    # Create Item
    # ==========================================================

    async def create_item(
        self,
        db: AsyncSession,
        day_id: str,
        user_id: str,
        payload: ItineraryItemCreate,
    ) -> ItineraryItem:
        """
        Create an itinerary item.
        """

        day = await self._get_user_day(
            db,
            day_id,
            user_id,
        )

        data = payload.model_dump()
        await self._validate_item(db, data)

        # ------------------------------------------------------
        # Automatically assign next sequence if default is used
        # ------------------------------------------------------

        if data.get("sequence", 1) == 1:
            max_sequence = (
                await self.repository.get_max_sequence(
                    db,
                    day.id,
                )
            )

            if max_sequence > 0:
                data["sequence"] = max_sequence + 1

        item = ItineraryItem(
            itinerary_day_id=day.id,
            **data,
        )

        return await self.repository.create_item(
            db,
            item,
        )

    # ==========================================================
    # Update Item
    # ==========================================================

    async def update_item(
        self,
        db: AsyncSession,
        item_id: str,
        user_id: str,
        payload: ItineraryItemUpdate,
    ) -> ItineraryItem:
        """
        Update an itinerary item.
        """

        item = await self._get_user_item(
            db,
            item_id,
            user_id,
        )

        values = payload.model_dump(
            exclude_unset=True,
        )

        if any(field in values and values[field] is None for field in ('title', 'activity_type', 'sequence')):
            raise HTTPException(422, 'Title, activity type and order cannot be empty.')
        combined = {field: getattr(item, field) for field in ('place_id', 'latitude', 'longitude', 'start_time', 'end_time')}
        combined.update(values)
        await self._validate_item(db, combined)
        if 'place_id' in values:
            values['latitude'], values['longitude'] = combined['latitude'], combined['longitude']

        return await self.repository.update_item(
            db,
            item,
            values,
        )

    @staticmethod
    async def _validate_item(db, data):
        if data.get('place_id'):
            place = await db.get(Place, data['place_id'])
            if place is None or place.is_deleted or not place.is_active:
                raise HTTPException(404, 'Place unavailable.')
            data['latitude'], data['longitude'] = place.latitude, place.longitude
        lat, lon = data.get('latitude'), data.get('longitude')
        if (lat is None) != (lon is None):
            raise HTTPException(422, 'Add both coordinates or leave both empty.')
        if lat is not None and (not -90 <= lat <= 90 or not -180 <= lon <= 180):
            raise HTTPException(422, 'Coordinates are outside the valid range.')
        start, end = data.get('start_time'), data.get('end_time')
        if start and end and end < start:
            raise HTTPException(422, 'End time must follow start time within the day.')

    # ==========================================================
    # Delete Item
    # ==========================================================

    async def delete_item(
        self,
        db: AsyncSession,
        item_id: str,
        user_id: str,
    ) -> None:
        """
        Delete an itinerary item.
        """

        await self._get_user_item(
            db,
            item_id,
            user_id,
        )

        await self.repository.delete_item(
            db,
            item_id,
        )

    async def reorder(self, db, day_id, user_id, item_ids):
        day = await self._get_user_day(db, day_id, user_id)
        items = {item.id: item for item in day.items}
        if len(set(item_ids)) != len(item_ids) or set(item_ids) != set(items):
            raise HTTPException(409, 'The day changed. Refresh it before reordering.')
        for sequence, identifier in enumerate(item_ids, start=1):
            items[identifier].sequence = sequence
        await db.commit()
        await db.refresh(day)
        await db.refresh(day, attribute_names=['items'])
        return day
