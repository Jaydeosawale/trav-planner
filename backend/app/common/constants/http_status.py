"""
HTTP status codes used by the application.
"""

from http import HTTPStatus


# ==========================================================
# Success
# ==========================================================

OK = HTTPStatus.OK
CREATED = HTTPStatus.CREATED
NO_CONTENT = HTTPStatus.NO_CONTENT


# ==========================================================
# Client Errors
# ==========================================================

BAD_REQUEST = HTTPStatus.BAD_REQUEST
UNAUTHORIZED = HTTPStatus.UNAUTHORIZED
FORBIDDEN = HTTPStatus.FORBIDDEN
NOT_FOUND = HTTPStatus.NOT_FOUND
CONFLICT = HTTPStatus.CONFLICT
UNPROCESSABLE_ENTITY = HTTPStatus.UNPROCESSABLE_ENTITY


# ==========================================================
# Server Errors
# ==========================================================

INTERNAL_SERVER_ERROR = HTTPStatus.INTERNAL_SERVER_ERROR