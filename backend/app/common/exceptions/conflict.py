"""
Conflict exception.
"""

from __future__ import annotations

from app.common.exceptions.app_exception import AppException


class ConflictException(AppException):
    """
    Raised when a resource conflicts with existing data.
    """

    def __init__(
        self,
        message: str = "Resource already exists.",
    ) -> None:
        super().__init__(
            message=message,
            status_code=409,
            error="CONFLICT",
        )