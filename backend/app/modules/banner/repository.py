from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import or_
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.banner.model import Banner
from app.repositories.base import BaseRepository


class BannerRepository(BaseRepository[Banner]):
    """
    Banner database operations.
    """

    def __init__(self) -> None:
        super().__init__(Banner)

    # ==========================================================
    # Admin
    # ==========================================================

    async def get_all_admin(
        self,
        db: AsyncSession,
    ) -> list[Banner]:
        """
        Return all non-deleted banners.

        Used by Admin CMS.
        """

        result = await db.execute(
            select(Banner)
            .where(
                Banner.is_deleted.is_(False)
            )
            .order_by(
                Banner.priority.desc(),
                Banner.display_order,
            )
        )

        return list(result.scalars().all())

    # ==========================================================
    # User Home
    # ==========================================================

    async def get_active_for_home(
        self,
        db: AsyncSession,
    ) -> list[Banner]:
        """
        Return banners that are currently active
        and within their schedule.
        """

        now = datetime.now(timezone.utc)

        result = await db.execute(
            select(Banner)
            .where(
                Banner.is_deleted.is_(False),
                Banner.is_active.is_(True),

                or_(
                    Banner.starts_at.is_(None),
                    Banner.starts_at <= now,
                ),

                or_(
                    Banner.ends_at.is_(None),
                    Banner.ends_at >= now,
                ),
            )
            .order_by(
                Banner.priority.desc(),
                Banner.display_order,
            )
        )

        return list(result.scalars().all())