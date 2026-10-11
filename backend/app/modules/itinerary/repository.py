"""
Itinerary repository.

Database access for itinerary days and items.
"""

from __future__ import annotations

from sqlalchemy import delete
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.itinerary.model import (
    ItineraryDay,
    ItineraryItem,
)


class ItineraryRepository:
    """
    Repository for itinerary database operations.
    """

    # ==========================================================
    # Trip Itinerary
    # ==========================================================

    async def get_days_by_trip(
        self,
        db: AsyncSession,
        trip_id: str,
    ) -> list[ItineraryDay]:
        """
        Get all itinerary days for a trip.

        Items are loaded together and ordered by sequence.
        """

        result = await db.execute(
            select(ItineraryDay)
            .where(
                ItineraryDay.trip_id == trip_id,
            )
            .options(
                selectinload(
                    ItineraryDay.items,
                )
            )
            .order_by(
                ItineraryDay.day_number,
            )
        )

        return list(
            result.scalars().unique().all()
        )

    # ==========================================================
    # Day
    # ==========================================================

    async def get_day_by_id(
        self,
        db: AsyncSession,
        day_id: str,
    ) -> ItineraryDay | None:
        """
        Get an itinerary day by ID.
        """

        result = await db.execute(
            select(ItineraryDay)
            .where(
                ItineraryDay.id == day_id,
            )
            .options(
                selectinload(
                    ItineraryDay.items,
                )
            )
        )

        return result.scalar_one_or_none()

    async def get_day_by_trip_and_number(
        self,
        db: AsyncSession,
        trip_id: str,
        day_number: int,
    ) -> ItineraryDay | None:
        """
        Get a specific day number within a trip.
        """

        result = await db.execute(
            select(ItineraryDay)
            .where(
                ItineraryDay.trip_id == trip_id,
                ItineraryDay.day_number == day_number,
            )
        )

        return result.scalar_one_or_none()

    async def create_day(
        self,
        db: AsyncSession,
        day: ItineraryDay,
    ) -> ItineraryDay:
        """
        Create an itinerary day.
        """

        db.add(day)

        await db.commit()
        await db.refresh(day)

        return day

    async def update_day(
        self,
        db: AsyncSession,
        day: ItineraryDay,
        values: dict,
    ) -> ItineraryDay:
        """
        Update an itinerary day.
        """

        for field, value in values.items():
            setattr(
                day,
                field,
                value,
            )

        await db.commit()
        await db.refresh(day)

        return day

    async def delete_day(
        self,
        db: AsyncSession,
        day_id: str,
    ) -> None:
        """
        Delete an itinerary day.

        Child items are deleted through the ORM relationship
        cascade.
        """

        day = await self.get_day_by_id(
            db,
            day_id,
        )

        if day is not None:
            await db.delete(day)
            await db.commit()

    # ==========================================================
    # Item
    # ==========================================================

    async def get_item_by_id(
        self,
        db: AsyncSession,
        item_id: str,
    ) -> ItineraryItem | None:
        """
        Get an itinerary item by ID.
        """

        result = await db.execute(
            select(ItineraryItem)
            .where(
                ItineraryItem.id == item_id,
            )
        )

        return result.scalar_one_or_none()

    async def get_items_by_day(
        self,
        db: AsyncSession,
        day_id: str,
    ) -> list[ItineraryItem]:
        """
        Get items belonging to an itinerary day.
        """

        result = await db.execute(
            select(ItineraryItem)
            .where(
                ItineraryItem.itinerary_day_id == day_id,
            )
            .order_by(
                ItineraryItem.sequence,
            )
        )

        return list(
            result.scalars().all()
        )

    async def create_item(
        self,
        db: AsyncSession,
        item: ItineraryItem,
    ) -> ItineraryItem:
        """
        Create an itinerary item.
        """

        db.add(item)

        await db.commit()
        await db.refresh(item)

        return item

    async def update_item(
        self,
        db: AsyncSession,
        item: ItineraryItem,
        values: dict,
    ) -> ItineraryItem:
        """
        Update an itinerary item.
        """

        for field, value in values.items():
            setattr(
                item,
                field,
                value,
            )

        await db.commit()
        await db.refresh(item)

        return item

    async def delete_item(
        self,
        db: AsyncSession,
        item_id: str,
    ) -> None:
        """
        Delete an itinerary item.
        """

        await db.execute(
            delete(ItineraryItem).where(
                ItineraryItem.id == item_id,
            )
        )

        await db.commit()

    # ==========================================================
    # Item Sequence
    # ==========================================================

    async def get_max_sequence(
        self,
        db: AsyncSession,
        day_id: str,
    ) -> int:
        """
        Get the current highest sequence number for a day.
        """

        result = await db.execute(
            select(ItineraryItem.sequence)
            .where(
                ItineraryItem.itinerary_day_id == day_id,
            )
            .order_by(
                ItineraryItem.sequence.desc(),
            )
            .limit(1)
        )

        value = result.scalar_one_or_none()

        return value or 0