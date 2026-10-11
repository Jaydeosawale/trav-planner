"""
Search intelligence service.

Current responsibility:
    Structured search orchestration.

Future responsibility:
    LLM query understanding
    user-context retrieval
    personalized ranking
    semantic search
    RAG
    agent orchestration
"""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.search.repository import SearchRepository
from app.modules.search.schema import SearchRequest
from app.modules.user.repository import UserRepository


class SearchService:
    """
    Unified search orchestration service.
    """

    def __init__(self) -> None:
        self.repository = SearchRepository()
        self.user_repository = UserRepository()

    # ======================================================
    # Search
    # ======================================================

    async def search(
        self,
        db: AsyncSession,
        payload: SearchRequest,
        *,
        user_id: str | None = None,
    ):
        """
        Execute unified search.

        Current pipeline:

            Request
                ↓
            Place retrieval
                ↓
            Results

        Future pipeline:

            Request
                ↓
            LLM intent extraction
                ↓
            User context
                ↓
            Retrieval
                ↓
            Personalized ranking
                ↓
            Agents / external tools
        """

        places, total = await self.repository.search_places(
            db,
            page=payload.page,
            size=payload.size,
            search=payload.query,
            country_id=payload.country_id,
            state_id=payload.state_id,
            city_id=payload.city_id,
            place_type=payload.place_type,
            category_id=payload.category_id,
        )

        pages = (
            (total + payload.size - 1) // payload.size
            if total > 0
            else 0
        )

        # --------------------------------------------------
        # User Context
        # --------------------------------------------------
        #
        # We intentionally retrieve the profile/history
        # here only when a user is authenticated.
        #
        # Ranking will be added after the deterministic
        # search foundation is verified.
        #

        if user_id is not None:
            profile = await self.user_repository.get_profile(
                db,
                user_id,
            )

            search_history = (
                await self.user_repository.get_search_history(
                    db,
                    user_id,
                    limit=10,
                )
            )

            # Keep these available for the next ranking layer.
            #
            # Do not modify the DB search result yet.
            #
            # Future:
            # personalized_places = rank_places(
            #     places,
            #     profile,
            #     search_history,
            # )

            _ = profile
            _ = search_history

        return (
            places,
            total,
            pages,
        )