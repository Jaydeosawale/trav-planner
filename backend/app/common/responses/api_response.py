"""
Standard API Response Models and Helpers.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Generic, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class ApiResponse(BaseModel, Generic[T]):
    """
    Standard response returned by every API.
    """

    success: bool = True
    message: str = "Success"
    data: T | None = None
    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
    )

    @classmethod
    def success(
        cls,
        data: Any = None,
        message: str = "Success",
    ) -> "ApiResponse[Any]":
        """
        Create a successful API response.
        """
        return cls(
            success=True,
            message=message,
            data=data,
        )


class PaginatedResponse(BaseModel, Generic[T]):
    """
    Standard paginated response.
    """

    success: bool = True
    message: str = "Success"
    data: list[T]
    total: int
    page: int
    size: int
    pages: int
    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
    )


class ErrorResponse(BaseModel):
    """
    Standard error response.
    """

    success: bool = False
    message: str
    error: str
    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
    )


def success_response(
    data: Any = None,
    message: str = "Success",
) -> ApiResponse[Any]:
    """
     Create a standard successful API response.
     """
    return ApiResponse(
        success=True,
        message=message,
        data=data,
    )
