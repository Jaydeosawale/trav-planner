"""
Trav Planner API
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import api_config
from app.core.lifespan import lifespan
from app.core.settings import settings

from app.middleware.request_id import RequestIDMiddleware
from app.middleware.logging import LoggingMiddleware
from app.middleware.exception import global_exception_handler
from app.common.exceptions.handler import register_exception_handlers

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
register_exception_handlers(app)

app.add_exception_handler(
    Exception,
    global_exception_handler,
)

app.add_middleware(RequestIDMiddleware)

app.add_middleware(LoggingMiddleware)

# ---------------------------------------------------------
# CORS
# ---------------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------
# API
# ---------------------------------------------------------

app.include_router(
    api_router,
    prefix=settings.API_PREFIX,
)

# ---------------------------------------------------------
# Root
# ---------------------------------------------------------

@app.get("/", tags=["Root"])
async def root():
    return {
        "application": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "status": "running",
    }