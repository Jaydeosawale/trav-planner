"""
Unified Search API.

This is the API used by the future AI Route screen.

Search may later accept natural-language requests
processed by the LLM layer.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import success_response
from app.database.session import get_db
from app.dependencies.current_user import get_current_user
from app.modules.auth.model import User
from app.modules.place.schema import PlaceResponse
from app.modules.search.schema import SearchRequest
from app.modules.search.schema import SearchResponse
from app.modules.search.schema import SearchResult
from app.modules.search.service import SearchService


router = APIRouter()

service = SearchService()


# ==========================================================
# Unified Search
# ==========================================================

@router.post(
    "/",
    response_model=None,
    summary="Unified travel search",
)
async def search(
    payload: SearchRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Unified authenticated travel search.

    Current:
        Structured database search.

    Future:
        Natural language
        LLM query understanding
        User personalization
        RAG
        AI agents
        Google Maps
        External travel services
    """

    places, total, pages = await service.search(
        db,
        payload,
        user_id=current_user.id,
    )

    result = SearchResult(
        items=[
            PlaceResponse.model_validate(place)
            for place in places
        ],
        total=total,
        page=payload.page,
        size=payload.size,
        pages=pages,
    )

    response = SearchResponse(
        query=payload.query,
        result=result,
    )

    return success_response(
        data=response,
        message="Search completed successfully",
    )