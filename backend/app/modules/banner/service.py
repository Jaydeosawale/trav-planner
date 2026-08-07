from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.banner.model import Banner
from app.modules.banner.repository import BannerRepository
from app.modules.banner.schema import BannerCreate
from app.modules.banner.schema import BannerUpdate
from app.services.base import BaseService


class BannerService(BaseService[Banner]):
    """
    Banner business logic.
    """

    def __init__(self) -> None:
        super().__init__(BannerRepository())

    async def create(
        self,
        db: AsyncSession,
        payload: BannerCreate,
    ) -> Banner:
        """
        Create banner.
        """

        banner = Banner(
            **payload.model_dump()
        )

        return await self.repository.create(
            db,
            banner,
        )

    async def update(
        self,
        db: AsyncSession,
        banner_id: str,
        payload: BannerUpdate,
    ) -> Banner | None:
        """
        Update banner.
        """

        banner = await self.repository.get_by_id(
            db,
            banner_id,
        )

        if banner is None:
            return None

        for key, value in payload.model_dump(
            exclude_unset=True,
        ).items():
            setattr(
                banner,
                key,
                value,
            )

        return await self.repository.update(
            db,
            banner,
        )

    async def delete(
        self,
        db: AsyncSession,
        banner_id: str,
    ) -> bool:
        """
        Soft delete banner.
        """

        banner = await self.repository.get_by_id(
            db,
            banner_id,
        )

        if banner is None:
            return False

        await self.repository.delete(
            db,
            banner,
        )

        return True