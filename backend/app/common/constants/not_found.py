"""
Not found exception.
"""

from __future__ import annotations

from app.common.exceptions.app_exception import AppException


class NotFoundException(AppException):
    """
    Raised when a requested resource does not exist.
    """

    def __init__(
        self,
        resource: str = "Resource",
    ) -> None:
        super().__init__(
            message=f"{resource} not found.",
            status_code=404,
            error="NOT_FOUND",
        )