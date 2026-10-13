"""
Place service.

Business logic for travel places.
"""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession
from slugify import slugify

from app.common.constants.not_found import NotFoundException
from app.common.exceptions.conflict import ConflictException
from app.modules.place.model import Place
from app.modules.place.repository import PlaceRepository
from app.modules.place.schema import (
    PlaceCreate,
    PlaceUpdate,
)
from app.services.base import BaseService


class PlaceService(BaseService[Place]):
    """
    Place business logic.
    """

    def __init__(self) -> None:
        super().__init__(
            PlaceRepository(),
        )

    # ==========================================================
    # Search / Pagination
    # ==========================================================

    async def search(
        self,
        db: AsyncSession,
        *,
        page: int = 1,
        size: int = 50,
        search: str | None = None,
        country_id: str | None = None,
        state_id: str | None = None,
        city_id: str | None = None,
        place_type: str | None = None,
        category_id: str | None = None,
    ) -> tuple[list[Place], int]:
        """
        Search and paginate active places.
        """

        return await self.repository.search(
            db,
            page=page,
            size=size,
            search=search,
            country_id=country_id,
            state_id=state_id,
            city_id=city_id,
            place_type=place_type,
            category_id=category_id,
            active_only=True,
        )

    # ==========================================================
    # Create
    # ==========================================================

    async def create(
        self,
        db: AsyncSession,
        payload: PlaceCreate,
    ) -> Place:
        """
        Create a place.
        """

        if await self.repository.exists_by_name(
            db,
            payload.name,
        ):
            raise ConflictException(
                "Place already exists."
            )

        if await self.repository.exists_by_slug(
            db,
            payload.slug,
        ):
            raise ConflictException(
                "Place slug already exists."
            )

        place = Place(
            **payload.model_dump(),
        )

        return await self.repository.create(
            db,
            place,
        )

    # ==========================================================
    # Update
    # ==========================================================

    async def update(
        self,
        db: AsyncSession,
        place_id: str,
        payload: PlaceUpdate,
    ) -> Place:
        """
        Update an existing place.
        """

        place = await self.repository.get_by_id(
            db,
            place_id,
            active_only=False,
        )

        if place is None:
            raise NotFoundException(
                "Place"
            )

        data = payload.model_dump(
            exclude_unset=True,
        )

        if place.content_revision == 'discovery-v1':
            data['content_revision'] = 'admin-edited'

        if 'image_url' in data and data['image_url'] != place.image_url and 'image_credit' not in data:
            data['image_credit'] = None

        # ------------------------------------------------------
        # Name
        # ------------------------------------------------------

        if "name" in data:
            name = data["name"]

            if (
                name
                and name != place.name
                and await self.repository.exists_by_name(
                    db,
                    name,
                )
            ):
                raise ConflictException(
                    "Place already exists."
                )

        # ------------------------------------------------------
        # Slug
        # ------------------------------------------------------

        if "slug" in data:
            slug = data["slug"]

            if (
                slug
                and slug != place.slug
                and await self.repository.exists_by_slug(
                    db,
                    slug,
                )
            ):
                raise ConflictException(
                    "Place slug already exists."
                )

        # ------------------------------------------------------
        # Apply Updates
        # ------------------------------------------------------

        for key, value in data.items():
            setattr(
                place,
                key,
                value,
            )

        return await self.repository.update(
            db,
            place,
        )

    # ==========================================================
    # Delete
    # ==========================================================

    async def delete(
        self,
        db: AsyncSession,
        place_id: str,
    ) -> bool:
        """
        Soft delete a place.
        """

        place = await self.repository.get_by_id(
            db,
            place_id,
            active_only=False,
        )

        if place is None:
            raise NotFoundException(
                "Place"
            )

        await self.repository.delete(
            db,
            place,
        )

        return True

    # ==========================================================
    # Get All
    # ==========================================================

    async def get_all(
        self,
        db: AsyncSession,
        *,
        active_only: bool = True,
    ) -> list[Place]:
        """
        Return places.
        """

        return await self.repository.get_all(
            db,
            active_only=active_only,
        )

    # ==========================================================
    # Get By ID
    # ==========================================================

    async def get_by_id(
        self,
        db: AsyncSession,
        place_id: str,
        *,
        active_only: bool = True,
    ) -> Place:
        """
        Return place by ID.
        """

        place = await self.repository.get_by_id(
            db,
            place_id,
            active_only=active_only,
        )

        if place is None:
            raise NotFoundException(
                "Place"
            )

        return place

    # ==========================================================
    # Get By Slug
    # ==========================================================

    async def get_by_slug(
        self,
        db: AsyncSession,
        slug: str,
        *,
        active_only: bool = True,
    ) -> Place:
        """
        Return place by slug.
        """

        place = await self.repository.get_by_slug(
            db,
            slug,
            active_only=active_only,
        )

        if place is None:
            raise NotFoundException(
                "Place"
            )

        return place