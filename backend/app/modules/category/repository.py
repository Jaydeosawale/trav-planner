from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.category.model import Category
from app.repositories.base import BaseRepository


class CategoryRepository(BaseRepository[Category]):
    """
    Category database operations.
    """

    def __init__(self) -> None:
        super().__init__(Category)

    async def get_all(
        self,
        db: AsyncSession,
    ) -> list[Category]:
        """
        Return all active categories ordered by display order.
        """

        result = await db.execute(
            select(Category)
            .where(
                Category.is_deleted.is_(False)
            )
            .order_by(
                Category.display_order,
                Category.name,
            )
        )

        return list(result.scalars().all())

    async def get_active(
        self,
        db: AsyncSession,
    ) -> list[Category]:
        """
        Return active categories.
        """

        result = await db.execute(
            select(Category)
            .where(
                Category.is_deleted.is_(False),
                Category.is_active.is_(True),
            )
            .order_by(
                Category.display_order,
                Category.name,
            )
        )

        return list(result.scalars().all())

    async def get_featured(
        self,
        db: AsyncSession,
    ) -> list[Category]:
        """
        Return featured categories.
        """

        result = await db.execute(
            select(Category)
            .where(
                Category.is_deleted.is_(False),
                Category.is_active.is_(True),
                Category.is_featured.is_(True),
            )
            .order_by(
                Category.display_order,
                Category.name,
            )
        )

        return list(result.scalars().all())

    async def get_root_categories(
        self,
        db: AsyncSession,
    ) -> list[Category]:
        """
        Return top-level categories.
        """

        result = await db.execute(
            select(Category)
            .where(
                Category.parent_id.is_(None),
                Category.is_deleted.is_(False),
            )
            .order_by(
                Category.display_order,
                Category.name,
            )
        )

        return list(result.scalars().all())

    async def get_children(
        self,
        db: AsyncSession,
        parent_id: str,
    ) -> list[Category]:
        """
        Return child categories.
        """

        result = await db.execute(
            select(Category)
            .where(
                Category.parent_id == parent_id,
                Category.is_deleted.is_(False),
            )
            .order_by(
                Category.display_order,
                Category.name,
            )
        )

        return list(result.scalars().all())

    async def exists_by_name(
        self,
        db: AsyncSession,
        name: str,
    ) -> bool:
        """
        Check whether a category name already exists.
        """

        result = await db.execute(
            select(Category.id).where(
                Category.name == name,
                Category.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none() is not None

    async def exists_by_slug(
        self,
        db: AsyncSession,
        slug: str,
    ) -> bool:
        """
        Check whether a slug already exists.
        """

        result = await db.execute(
            select(Category.id).where(
                Category.slug == slug,
                Category.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none() is not None