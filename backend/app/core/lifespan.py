"""
Application lifespan.

Handles startup and shutdown events.
"""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.core.logging import configure_logging
from app.core.logging import get_logger


logger = get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application startup/shutdown lifecycle.
    """

    configure_logging()

    logger.info("=====================================")
    logger.info("Trav Planner API Starting...")
    logger.info("=====================================")

    # ==========================================================
    # SQLAlchemy model registration
    # ==========================================================
    #
    # Import all models during application startup so SQLAlchemy
    # knows about every model before relationships are configured.
    #
    # Example:
    # Place -> Category
    # Place -> City
    #
    import app.database.models  # noqa: F401

    logger.info("Database models registered.")

    # ==========================================================
    # Future startup tasks
    # ==========================================================
    #
    # Database connection
    # Redis
    # AI Platform
    # Scheduler
    # Cache
    # Workers

    yield

    # ==========================================================
    # Shutdown
    # ==========================================================

    logger.info("=====================================")
    logger.info("Trav Planner API Stopped")
    logger.info("=====================================")