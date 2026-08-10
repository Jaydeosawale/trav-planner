"""
Forbidden exception.
"""

from __future__ import annotations

from app.common.exceptions.app_exception import AppException


class ForbiddenException(AppException):
    """
    Raised when the user is authenticated but
    does not have permission to perform an action.
    """

    def __init__(
        self,
        message: str = "You do not have permission to perform this action.",
    ) -> None:
        super().__init__(
            message=message,
            status_code=403,
            error="FORBIDDEN",
        )