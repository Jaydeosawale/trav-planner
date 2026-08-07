"""
Application lifespan management.

Handles application startup and shutdown.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.core.logging import configure_logging, get_logger

logger = get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application startup and shutdown lifecycle.
    """

    # ---------------------------------------------------------
    # Startup
    # ---------------------------------------------------------

    configure_logging()

    logger.info("=" * 60)
    logger.info("Starting Trav Planner API")
    logger.info("=" * 60)

    # Future startup tasks
    #
    # PostgreSQL connection
    # Redis connection
    # AI Platform
    # Scheduler
    # Cache
    # Workers

    yield

    # ---------------------------------------------------------
    # Shutdown
    # ---------------------------------------------------------

    logger.info("=" * 60)
    logger.info("Stopping Trav Planner API")
    logger.info("=" * 60)