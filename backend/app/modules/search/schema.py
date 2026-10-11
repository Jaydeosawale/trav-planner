"""
Search schemas.

Search is the orchestration layer above the individual
domain modules such as places and destinations.
"""

from __future__ import annotations

from pydantic import BaseModel
from pydantic import Field

from app.modules.place.schema import PlaceResponse


# ==========================================================
# Search Request
# ==========================================================

class SearchRequest(BaseModel):
    """
    Unified search request.

    This schema intentionally represents structured search
    parameters. Natural-language understanding can later
    populate this structure through an LLM.
    """

    query: str | None = Field(
        default=None,
        min_length=1,
        max_length=500,
    )

    country_id: str | None = None

    state_id: str | None = None

    city_id: str | None = None

    place_type: str | None = None

    category_id: str | None = None

    page: int = Field(
        default=1,
        ge=1,
    )

    size: int = Field(
        default=20,
        ge=1,
        le=100,
    )


# ==========================================================
# Search Result
# ==========================================================

class SearchResult(BaseModel):
    """
    Search result containing places.

    This is intentionally a stable API contract so that
    Flutter does not need to know how search is implemented.
    """

    items: list[PlaceResponse]

    total: int

    page: int

    size: int

    pages: int


# ==========================================================
# Search Response
# ==========================================================

class SearchResponse(BaseModel):
    """
    Unified search response.
    """

    query: str | None

    result: SearchResult