from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession
from slugify import slugify

from app.modules.category.model import Category
from app.modules.category.repository import CategoryRepository
from app.modules.category.schema import (
    CategoryCreate,
    CategoryUpdate,
)
from app.services.base import BaseService
from app.common.exceptions.conflict import ConflictException
from app.common.constants.not_found import NotFoundException


class CategoryService(BaseService[Category]):
    """
    Category business logic.
    """

    def __init__(self) -> None:
        super().__init__(CategoryRepository())

    async def create(
        self,
        db: AsyncSession,
        payload: CategoryCreate,
    ) -> Category:
        """
        Create category.
        """

        if await self.repository.exists_by_name(
            db,
            payload.name,
        ):
            raise ConflictException(
                "Category already exists."
            )

        slug = slugify(payload.name)

        if await self.repository.exists_by_slug(
            db,
            slug,
        ):
            raise ConflictException(
                "Category slug already exists."
            )

        if payload.parent_id:

            parent = await self.repository.get_by_id(
                db,
                payload.parent_id,
            )

            if parent is None:
                raise NotFoundException(
                    "Parent category"
                )

        category = Category(
            **payload.model_dump(),
            slug=slug,
        )

        return await self.repository.create(
            db,
            category,
        )

    async def update(
        self,
        db: AsyncSession,
        category_id: str,
        payload: CategoryUpdate,
    ) -> Category:
        """
        Update category.
        """

        category = await self.repository.get_by_id(
            db,
            category_id,
        )

        if category is None:
            raise NotFoundException(
                "Category"
            )

        if (
            payload.parent_id
            and payload.parent_id == category.id
        ):
            raise ConflictException(
                "Category cannot be its own parent."
            )

        data = payload.model_dump(
            exclude_unset=True,
        )

        if "name" in data:

            slug = slugify(data["name"])

            if (
                slug != category.slug
                and await self.repository.exists_by_slug(
                    db,
                    slug,
                )
            ):
                raise ConflictException(
                    "Category slug already exists."
                )

            data["slug"] = slug

        if data.get("parent_id"):

            parent = await self.repository.get_by_id(
                db,
                data["parent_id"],
            )

            if parent is None:
                raise NotFoundException(
                    "Parent category"
                )

        for key, value in data.items():
            setattr(
                category,
                key,
                value,
            )

        return await self.repository.update(
            db,
            category,
        )

    async def delete(
        self,
        db: AsyncSession,
        category_id: str,
    ) -> bool:
        """
        Soft delete category.
        """

        category = await self.repository.get_by_id(
            db,
            category_id,
        )

        if category is None:
            raise NotFoundException(
                "Category"
            )

        await self.repository.delete(
            db,
            category,
        )

        return True

    async def get_featured(
        self,
        db: AsyncSession,
    ):
        return await self.repository.get_featured(db)

    async def get_active(
        self,
        db: AsyncSession,
    ):
        return await self.repository.get_active(db)

    async def get_root_categories(
        self,
        db: AsyncSession,
    ):
        return await self.repository.get_root_categories(
            db
        )

    async def get_children(
        self,
        db: AsyncSession,
        parent_id: str,
    ):
        return await self.repository.get_children(
            db,
            parent_id,
        )