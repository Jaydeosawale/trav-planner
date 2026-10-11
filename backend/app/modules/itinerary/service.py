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

from sqlalchemy.ext.asyncio import AsyncSession

from app.common.exceptions.forbidden import ForbiddenException
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

        await self._get_user_trip(
            db,
            trip_id,
            user_id,
        )

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

        return await self.repository.update_item(
            db,
            item,
            values,
        )

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
