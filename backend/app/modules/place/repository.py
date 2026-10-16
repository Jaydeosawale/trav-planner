"""
Place repository.

Database operations for travel places.
"""

from __future__ import annotations

from sqlalchemy import func
from sqlalchemy import or_
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.city.model import City
from app.modules.country.model import Country
from app.modules.state.model import State
from app.modules.place.model import Place
from app.repositories.base import BaseRepository


class PlaceRepository(BaseRepository[Place]):
    """
    Database operations for Place.
    """

    def __init__(self) -> None:
        super().__init__(Place)

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

        When active_only is True, only active and non-deleted
        places are returned.
        """

        filters = [
            Place.is_deleted.is_(False),
        ]

        if active_only:
            filters.append(
                Place.is_active.is_(True),
            )

        result = await db.execute(
            select(Place)
            .options(
                selectinload(Place.city),
                selectinload(Place.category),
            )
            .where(*filters)
            .order_by(
                Place.is_featured.desc(),
                Place.name,
            )
        )

        return list(result.scalars().all())

    # ==========================================================
    # Get By ID
    # ==========================================================

    async def get_by_id(
        self,
        db: AsyncSession,
        place_id: str,
        *,
        active_only: bool = True,
    ) -> Place | None:
        """
        Return place by ID.
        """

        filters = [
            Place.id == place_id,
            Place.is_deleted.is_(False),
        ]

        if active_only:
            filters.append(
                Place.is_active.is_(True),
            )

        result = await db.execute(
            select(Place)
            .options(
                selectinload(Place.city),
                selectinload(Place.category),
            )
            .where(*filters)
        )

        return result.scalar_one_or_none()

    # ==========================================================
    # Get By Slug
    # ==========================================================

    async def get_by_slug(
        self,
        db: AsyncSession,
        slug: str,
        *,
        active_only: bool = True,
    ) -> Place | None:
        """
        Return place by slug.
        """

        filters = [
            Place.slug == slug,
            Place.is_deleted.is_(False),
        ]

        if active_only:
            filters.append(
                Place.is_active.is_(True),
            )

        result = await db.execute(
            select(Place)
            .options(
                selectinload(Place.city),
                selectinload(Place.category),
            )
            .where(*filters)
        )

        return result.scalar_one_or_none()

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
        active_only: bool = True,
        has_photo: bool = False,
    ) -> tuple[list[Place], int]:
        """
        Search and paginate places.

        Supports:

        - Text search
        - Country filtering
        - State / province filtering
        - City filtering
        - Place type filtering
        - Category filtering
        - Active/inactive filtering
        - Pagination

        Country and state filters are resolved through:

            Place -> City -> Country / State
        """

        # ------------------------------------------------------
        # Base filters
        # ------------------------------------------------------

        filters = [
            Place.is_deleted.is_(False),
        ]

        if active_only:
            filters.append(
                Place.is_active.is_(True)
                & Place.city.has(
                    City.is_active.is_(True)
                    & City.is_deleted.is_(False)
                    & City.country.has(
                        Country.is_active.is_(True) & Country.is_deleted.is_(False)
                    )
                    & City.state.has(
                        State.is_active.is_(True) & State.is_deleted.is_(False)
                    )
                ),
            )

        # ------------------------------------------------------
        # Text Search
        # ------------------------------------------------------

        if search:
            search_value = search.strip()

            if search_value:
                search_pattern = f"%{search_value}%"

                filters.append(
                    or_(
                        Place.city.has(City.name.ilike(search_pattern)),
                        Place.name.ilike(
                            search_pattern,
                        ),
                        Place.place_type.ilike(
                            search_pattern,
                        ),
                        Place.short_description.ilike(
                            search_pattern,
                        ),
                        Place.description.ilike(
                            search_pattern,
                        ),
                        Place.address.ilike(
                            search_pattern,
                        ),
                        Place.locality.ilike(
                            search_pattern,
                        ),
                        Place.provider.ilike(
                            search_pattern,
                        ),
                        Place.external_place_id.ilike(
                            search_pattern,
                        ),
                    )
                )

        # ------------------------------------------------------
        # Country / State Relationship
        # ------------------------------------------------------

        needs_city_join = country_id is not None or state_id is not None

        # ------------------------------------------------------
        # City Filter
        # ------------------------------------------------------

        if city_id:
            filters.append(
                Place.city_id == city_id,
            )

        # ------------------------------------------------------
        # Place Type
        # ------------------------------------------------------

        if place_type:
            filters.append(
                Place.place_type == place_type,
            )

        # ------------------------------------------------------
        # Category
        # ------------------------------------------------------

        if category_id:
            filters.append(
                Place.category_id == category_id,
            )

        if country_id:
            filters.append(City.country_id == country_id)
        if state_id:
            filters.append(City.state_id == state_id)
        if has_photo:
            filters.append(
                or_(Place.image_url.like("https://%"), Place.image_url.like("http://%"))
            )

        # ------------------------------------------------------
        # Count Query
        # ------------------------------------------------------

        count_query = select(func.count()).select_from(Place)

        if needs_city_join:
            count_query = count_query.join(
                Place.city,
            )

        count_query = count_query.where(
            *filters,
        )

        count_result = await db.execute(
            count_query,
        )

        total = count_result.scalar_one()

        # ------------------------------------------------------
        # Main Query
        # ------------------------------------------------------

        query = select(Place).options(
            selectinload(Place.city),
            selectinload(Place.category),
        )

        if needs_city_join:
            query = query.join(
                Place.city,
            )

        query = query.where(
            *filters,
        )

        # ------------------------------------------------------
        # Ordering
        # ------------------------------------------------------

        query = query.order_by(
            Place.is_featured.desc(),
            Place.rating.desc().nullslast(),
            Place.name,
            Place.id,
        )

        # ------------------------------------------------------
        # Pagination
        # ------------------------------------------------------

        offset = (page - 1) * size

        query = query.offset(
            offset,
        ).limit(
            size,
        )

        result = await db.execute(
            query,
        )

        places = list(result.scalars().all())

        return places, total

    # ==========================================================
    # Exists By Name
    # ==========================================================

    async def exists_by_name(
        self,
        db: AsyncSession,
        name: str,
    ) -> bool:
        """
        Check whether a place name already exists.
        """

        result = await db.execute(
            select(Place.id).where(
                Place.name == name,
                Place.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none() is not None

    # ==========================================================
    # Exists By Slug
    # ==========================================================

    async def exists_by_slug(
        self,
        db: AsyncSession,
        slug: str,
    ) -> bool:
        """
        Check whether a place slug already exists.
        """

        result = await db.execute(
            select(Place.id).where(
                Place.slug == slug,
                Place.is_deleted.is_(False),
            )
        )

        return result.scalar_one_or_none() is not None
