"""
User travel profile and behavior repository.
"""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.place.model import Place
from app.modules.user.model import (
    UserPlaceLike,
    UserPlaceSave,
    UserPlaceView,
    UserSearchHistory,
    UserTravelProfile,
)


class UserRepository:
    """
    Database operations for user travel intelligence.
    """

    # ======================================================
    # Travel Profile
    # ======================================================

    async def get_profile(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> UserTravelProfile | None:

        result = await db.execute(
            select(UserTravelProfile).where(
                UserTravelProfile.user_id == user_id,
            )
        )

        return result.scalar_one_or_none()

    async def create_profile(
        self,
        db: AsyncSession,
        profile: UserTravelProfile,
    ) -> UserTravelProfile:

        db.add(profile)
        await db.commit()
        await db.refresh(profile)

        return profile

    async def update_profile(
        self,
        db: AsyncSession,
        profile: UserTravelProfile,
    ) -> UserTravelProfile:

        await db.commit()
        await db.refresh(profile)

        return profile

    # ======================================================
    # Search History
    # ======================================================

    async def add_search(
        self,
        db: AsyncSession,
        search: UserSearchHistory,
    ) -> UserSearchHistory:

        db.add(search)
        await db.commit()
        await db.refresh(search)

        return search

    async def get_search_history(
        self,
        db: AsyncSession,
        user_id: str,
        limit: int = 50,
    ) -> list[UserSearchHistory]:

        result = await db.execute(
            select(UserSearchHistory)
            .where(
                UserSearchHistory.user_id == user_id,
                UserSearchHistory.is_deleted.is_(False),
            )
            .order_by(
                UserSearchHistory.created_at.desc(),
            )
            .limit(limit)
        )

        return list(result.scalars().all())

    # ======================================================
    # Likes
    # ======================================================

    async def get_like(
        self,
        db: AsyncSession,
        user_id: str,
        place_id: str,
    ) -> UserPlaceLike | None:

        result = await db.execute(
            select(UserPlaceLike).where(
                UserPlaceLike.user_id == user_id,
                UserPlaceLike.place_id == place_id,
            )
        )

        return result.scalar_one_or_none()

    async def add_like(
        self,
        db: AsyncSession,
        like: UserPlaceLike,
    ) -> UserPlaceLike:

        db.add(like)
        await db.commit()
        await db.refresh(like)

        return like

    async def delete_like(
        self,
        db: AsyncSession,
        like: UserPlaceLike,
    ) -> None:

        await db.delete(like)
        await db.commit()

    async def get_liked_places(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> list[Place]:

        result = await db.execute(
            select(Place)
            .join(
                UserPlaceLike,
                UserPlaceLike.place_id == Place.id,
            )
            .where(
                UserPlaceLike.user_id == user_id,
                Place.is_deleted.is_(False),
            )
            .order_by(
                UserPlaceLike.created_at.desc(),
            )
        )

        return list(result.scalars().all())

    # ======================================================
    # Saves
    # ======================================================

    async def get_save(
        self,
        db: AsyncSession,
        user_id: str,
        place_id: str,
    ) -> UserPlaceSave | None:

        result = await db.execute(
            select(UserPlaceSave).where(
                UserPlaceSave.user_id == user_id,
                UserPlaceSave.place_id == place_id,
            )
        )

        return result.scalar_one_or_none()

    async def add_save(
        self,
        db: AsyncSession,
        save: UserPlaceSave,
    ) -> UserPlaceSave:

        db.add(save)
        await db.commit()
        await db.refresh(save)

        return save

    async def delete_save(
        self,
        db: AsyncSession,
        save: UserPlaceSave,
    ) -> None:

        await db.delete(save)
        await db.commit()

    async def get_saved_places(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> list[Place]:

        result = await db.execute(
            select(Place)
            .join(
                UserPlaceSave,
                UserPlaceSave.place_id == Place.id,
            )
            .where(
                UserPlaceSave.user_id == user_id,
                Place.is_deleted.is_(False),
            )
            .order_by(
                UserPlaceSave.created_at.desc(),
            )
        )

        return list(result.scalars().all())

    # ======================================================
    # Views
    # ======================================================

    async def add_view(
        self,
        db: AsyncSession,
        view: UserPlaceView,
    ) -> UserPlaceView:

        db.add(view)
        await db.commit()
        await db.refresh(view)

        return view