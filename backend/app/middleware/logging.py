"""
Request Logging Middleware.
"""

from __future__ import annotations

import time

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.core.logging import get_logger

logger = get_logger()


class LoggingMiddleware(BaseHTTPMiddleware):
    """
    Logs every HTTP request.
    """

    async def dispatch(self, request: Request, call_next):
        start = time.perf_counter()

        response = await call_next(request)

        elapsed = (time.perf_counter() - start) * 1000

        logger.info(
            "{} {} -> {} ({:.2f} ms)",
            request.method,
            request.url.path,
            response.status_code,
            elapsed,
        )

        return response