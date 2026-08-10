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

    # Future startup tasks
    #
    # Database connection
    # Redis
    # AI Platform
    # Scheduler
    # Cache
    # Workers

    yield

    logger.info("=====================================")
    logger.info("Trav Planner API Stopped")
    logger.info("=====================================")