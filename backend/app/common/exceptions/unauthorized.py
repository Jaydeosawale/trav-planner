"""
Unauthorized exception.
"""

from __future__ import annotations

from app.common.exceptions.app_exception import AppException


class UnauthorizedException(AppException):
    """
    Raised when authentication is required or invalid.
    """

    def __init__(
        self,
        message: str = "Authentication required.",
    ) -> None:
        super().__init__(
            message=message,
            status_code=401,
            error="UNAUTHORIZED",
        )