from __future__ import annotations

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

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[Banner]:
        """
        Return all active banners ordered by display order.
        """

        result = await db.execute(
            select(Banner)
            .where(
                Banner.is_deleted.is_(False)
            )
            .order_by(
                Banner.display_order
            )
        )

        return list(
            result.scalars().all()
        )