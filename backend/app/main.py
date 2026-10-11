"""
Trav Planner API.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import api_config
from app.core.lifespan import lifespan
from app.core.settings import settings

from app.middleware.exception import global_exception_handler
from app.middleware.logging import LoggingMiddleware
from app.middleware.request_id import RequestIDMiddleware


app = FastAPI(
    title=api_config.title,
    description=api_config.description,
    version=api_config.version,
    docs_url=api_config.docs_url,
    redoc_url=api_config.redoc_url,
    openapi_url=api_config.openapi_url,
    openapi_tags=api_config.openapi_tags,
    lifespan=lifespan,
)


# ==========================================================
# Exception Handling
# ==========================================================

app.add_exception_handler(
    Exception,
    global_exception_handler,
)


# ==========================================================
# Middleware
# ==========================================================

app.add_middleware(RequestIDMiddleware)

app.add_middleware(LoggingMiddleware)


# ==========================================================
# CORS
# ==========================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_origin_regex=settings.ALLOWED_ORIGIN_REGEX or None,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==========================================================
# API
# ==========================================================

app.include_router(
    api_router,
    prefix=settings.API_PREFIX,
)


# ==========================================================
# Root
# ==========================================================

@app.get(
    "/",
    tags=["Root"],
)
async def root():
    return {
        "application": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "status": "running",
    }

@app.get('/health', tags=['Health'])
async def health():
    """Readiness check: Render only routes traffic once PostgreSQL is reachable."""
    from sqlalchemy import text
    from app.database.session import engine
    async with engine.connect() as connection:
        await connection.execute(text('SELECT 1'))
    return {'status': 'ok'}
