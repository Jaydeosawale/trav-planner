"""
Planner business logic.
"""

from __future__ import annotations

from datetime import date

from sqlalchemy.ext.asyncio import AsyncSession

from app.common.constants.not_found import NotFoundException
from app.common.exceptions.conflict import ConflictException
from app.modules.destination.repository import DestinationRepository
from app.modules.planner.model import Planner
from app.modules.planner.repository import PlannerRepository
from app.modules.planner.schema import PlannerCreate
from app.modules.planner.schema import PlannerUpdate


class PlannerService:
    """
    Business logic for travel planners.
    """

    def __init__(self) -> None:
        self.repository = PlannerRepository()
        self.destination_repository = DestinationRepository()

    # ==========================================================
    # Create
    # ==========================================================

    async def create(
        self,
        db: AsyncSession,
        user_id: str,
        payload: PlannerCreate,
    ) -> Planner:
        """
        Create a planner for the authenticated user.
        """

        self._validate_dates(
            payload.start_date,
            payload.end_date,
        )

        destination = await self.destination_repository.get_by_id(
            db,
            payload.destination_id,
        )

        if destination is None:
            raise NotFoundException("Destination")

        planner = Planner(
            user_id=user_id,
            destination_id=payload.destination_id,
            title=payload.title,
            start_date=payload.start_date,
            end_date=payload.end_date,
            travelers=payload.travelers,
            budget_amount=payload.budget_amount,
            budget_currency=payload.budget_currency.upper(),
            travel_style=payload.travel_style,
            preferences=payload.preferences,
            status="draft",
        )

        planner = await self.repository.create(
            db,
            planner,
        )

        await db.commit()

        return planner

    # ==========================================================
    # Get All For User
    # ==========================================================

    async def get_all(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> list[Planner]:
        """
        Get all planners belonging to the authenticated user.
        """

        return await self.repository.get_all_for_user(
            db,
            user_id,
        )

    # ==========================================================
    # Get By ID
    # ==========================================================

    async def get_by_id(
        self,
        db: AsyncSession,
        planner_id: str,
        user_id: str,
    ) -> Planner:
        """
        Get a planner belonging to the authenticated user.
        """

        planner = await self.repository.get_by_id_for_user(
            db,
            planner_id,
            user_id,
        )

        if planner is None:
            raise NotFoundException("Planner")

        return planner

    # ==========================================================
    # Update
    # ==========================================================

    async def update(
        self,
        db: AsyncSession,
        planner_id: str,
        user_id: str,
        payload: PlannerUpdate,
    ) -> Planner:
        """
        Update a user's planner.
        """

        planner = await self.repository.get_by_id_for_user(
            db,
            planner_id,
            user_id,
        )

        if planner is None:
            raise NotFoundException("Planner")

        update_data = payload.model_dump(
            exclude_unset=True,
        )

        new_start_date = update_data.get(
            "start_date",
            planner.start_date,
        )

        new_end_date = update_data.get(
            "end_date",
            planner.end_date,
        )

        self._validate_dates(
            new_start_date,
            new_end_date,
        )

        if "destination_id" in update_data:
            destination = await self.destination_repository.get_by_id(
                db,
                update_data["destination_id"],
            )

            if destination is None:
                raise NotFoundException("Destination")

        if "budget_currency" in update_data:
            update_data["budget_currency"] = (
                update_data["budget_currency"].upper()
            )

        for field, value in update_data.items():
            setattr(
                planner,
                field,
                value,
            )

        planner = await self.repository.update(
            db,
            planner,
        )

        await db.commit()

        return planner

    # ==========================================================
    # Delete
    # ==========================================================

    async def delete(
        self,
        db: AsyncSession,
        planner_id: str,
        user_id: str,
    ) -> None:
        """
        Soft delete a user's planner.
        """

        planner = await self.repository.get_by_id_for_user(
            db,
            planner_id,
            user_id,
        )

        if planner is None:
            raise NotFoundException("Planner")

        await self.repository.soft_delete(
            db,
            planner,
        )

        await db.commit()

    # ==========================================================
    # Validation
    # ==========================================================

    @staticmethod
    def _validate_dates(
        start_date: date,
        end_date: date,
    ) -> None:
        """
        Validate travel dates.
        """

        if start_date > end_date:
            raise ConflictException(
                "Start date cannot be after end date."
            )