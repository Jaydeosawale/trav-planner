"""
Base application exception.
"""

from __future__ import annotations


class AppException(Exception):
    """
    Base exception for application-level errors.
    """

    def __init__(
        self,
        message: str,
        status_code: int = 500,
        error: str = "INTERNAL_SERVER_ERROR",
    ) -> None:
        self.message = message
        self.status_code = status_code
        self.error = error

        super().__init__(message)