"""
User travel intelligence service.
"""

from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.common.constants.not_found import NotFoundException
from app.modules.place.repository import PlaceRepository
from app.modules.user.model import (
    UserPlaceLike,
    UserPlaceSave,
    UserPlaceView,
    UserSearchHistory,
    UserTravelProfile,
)
from app.modules.user.repository import UserRepository
from app.modules.user.schema import (
    UserSearchHistoryCreate,
    UserTravelProfileCreate,
    UserTravelProfileUpdate,
)


class UserService:
    """
    User travel profile and behavior business logic.
    """

    def __init__(self) -> None:
        self.repository = UserRepository()
        self.place_repository = PlaceRepository()

    # ======================================================
    # Profile
    # ======================================================

    async def get_profile(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> UserTravelProfile | None:

        return await self.repository.get_profile(
            db,
            user_id,
        )

    async def create_or_update_profile(
        self,
        db: AsyncSession,
        user_id: str,
        payload: (
            UserTravelProfileCreate
            | UserTravelProfileUpdate
        ),
    ) -> UserTravelProfile:

        profile = await self.repository.get_profile(
            db,
            user_id,
        )

        data = payload.model_dump(
            exclude_unset=True,
        )

        if profile is None:
            profile = UserTravelProfile(
                user_id=user_id,
                **data,
            )

            return await self.repository.create_profile(
                db,
                profile,
            )

        for key, value in data.items():
            setattr(
                profile,
                key,
                value,
            )

        return await self.repository.update_profile(
            db,
            profile,
        )

    # ======================================================
    # Search History
    # ======================================================

    async def add_search(
        self,
        db: AsyncSession,
        user_id: str,
        payload: UserSearchHistoryCreate,
    ) -> UserSearchHistory:

        search = UserSearchHistory(
            user_id=user_id,
            **payload.model_dump(),
        )

        return await self.repository.add_search(
            db,
            search,
        )

    async def get_search_history(
        self,
        db: AsyncSession,
        user_id: str,
        limit: int = 50,
    ) -> list[UserSearchHistory]:

        return await self.repository.get_search_history(
            db,
            user_id,
            limit,
        )

    # ======================================================
    # Like
    # ======================================================

    async def like_place(
        self,
        db: AsyncSession,
        user_id: str,
        place_id: str,
    ) -> UserPlaceLike:

        place = await self.place_repository.get_by_id(
            db,
            place_id,
            active_only=True,
        )

        if place is None:
            raise NotFoundException("Place")

        existing = await self.repository.get_like(
            db,
            user_id,
            place_id,
        )

        if existing:
            return existing

        like = UserPlaceLike(
            user_id=user_id,
            place_id=place_id,
        )

        return await self.repository.add_like(
            db,
            like,
        )

    async def unlike_place(
        self,
        db: AsyncSession,
        user_id: str,
        place_id: str,
    ) -> None:

        existing = await self.repository.get_like(
            db,
            user_id,
            place_id,
        )

        if existing:
            await self.repository.delete_like(
                db,
                existing,
            )

    async def get_liked_places(
        self,
        db: AsyncSession,
        user_id: str,
    ):

        return await self.repository.get_liked_places(
            db,
            user_id,
        )

    # ======================================================
    # Save
    # ======================================================

    async def save_place(
        self,
        db: AsyncSession,
        user_id: str,
        place_id: str,
    ) -> UserPlaceSave:

        place = await self.place_repository.get_by_id(
            db,
            place_id,
            active_only=True,
        )

        if place is None:
            raise NotFoundException("Place")

        existing = await self.repository.get_save(
            db,
            user_id,
            place_id,
        )

        if existing:
            return existing

        save = UserPlaceSave(
            user_id=user_id,
            place_id=place_id,
        )

        return await self.repository.add_save(
            db,
            save,
        )

    async def unsave_place(
        self,
        db: AsyncSession,
        user_id: str,
        place_id: str,
    ) -> None:

        existing = await self.repository.get_save(
            db,
            user_id,
            place_id,
        )

        if existing:
            await self.repository.delete_save(
                db,
                existing,
            )

    async def get_saved_places(
        self,
        db: AsyncSession,
        user_id: str,
    ):

        return await self.repository.get_saved_places(
            db,
            user_id,
        )

    # ======================================================
    # View
    # ======================================================

    async def record_place_view(
        self,
        db: AsyncSession,
        user_id: str,
        place_id: str,
    ) -> UserPlaceView:

        place = await self.place_repository.get_by_id(
            db,
            place_id,
            active_only=True,
        )

        if place is None:
            raise NotFoundException("Place")

        view = UserPlaceView(
            user_id=user_id,
            place_id=place_id,
            viewed_at=datetime.now(timezone.utc),
        )

        return await self.repository.add_view(
            db,
            view,
        )