"""
Pagination dependencies.
"""

from __future__ import annotations

from fastapi import Query
from pydantic import BaseModel


class PaginationParams(BaseModel):
    """
    Common pagination parameters.
    """

    page: int = 1
    page_size: int = 20

    @property
    def offset(self) -> int:
        """
        Calculate database offset.
        """
        return (self.page - 1) * self.page_size


def get_pagination(
    page: int = Query(
        1,
        ge=1,
        description="Page number",
    ),
    page_size: int = Query(
        20,
        ge=1,
        le=100,
        description="Number of records per page",
    ),
) -> PaginationParams:
    """
    FastAPI pagination dependency.
    """

    return PaginationParams(
        page=page,
        page_size=page_size,
    )