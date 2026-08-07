"""
Request ID Middleware.
"""

from __future__ import annotations

import time
import uuid

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request


class RequestIDMiddleware(BaseHTTPMiddleware):
    """
    Adds a unique request ID to every request.
    """

    async def dispatch(self, request: Request, call_next):
        request_id = str(uuid.uuid4())

        request.state.request_id = request_id

        start_time = time.perf_counter()

        response = await call_next(request)

        process_time = time.perf_counter() - start_time

        response.headers["X-Request-ID"] = request_id
        response.headers["X-Process-Time"] = f"{process_time:.4f}s"

        return response