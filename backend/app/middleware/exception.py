"""
Global Exception Middleware.
"""

from __future__ import annotations

from fastapi import Request
from fastapi.responses import JSONResponse

from app.common.exceptions.base import AppException
from app.core.logging import get_logger

logger = get_logger()


async def global_exception_handler(
    request: Request,
    exc: Exception,
):
    """
    Handles all application exceptions.
    """

    # ---------------------------------------------
    # Custom application exceptions
    # ---------------------------------------------

    if isinstance(exc, AppException):
        logger.warning(exc.message)

        return JSONResponse(
            status_code=exc.status_code,
            content={
                "success": False,
                "message": exc.message,
                "error": exc.error,
            },
        )

    # ---------------------------------------------
    # Unexpected exceptions
    # ---------------------------------------------

    logger.exception(exc)

    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "message": "Internal Server Error",
            "error": "INTERNAL_SERVER_ERROR",
        },
    )