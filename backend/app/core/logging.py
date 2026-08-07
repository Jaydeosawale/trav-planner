"""
Application logging configuration.
"""

from __future__ import annotations

import sys
from pathlib import Path

from loguru import logger

from app.core.settings import settings


LOG_DIRECTORY = Path("logs")
LOG_DIRECTORY.mkdir(exist_ok=True)


def configure_logging() -> None:
    """
    Configure Loguru for the application.
    """

    logger.remove()

    # Console logger
    logger.add(
        sys.stdout,
        level=settings.LOG_LEVEL,
        colorize=True,
        enqueue=True,
        backtrace=True,
        diagnose=settings.DEBUG,
        format=(
            "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
            "<level>{level:<8}</level> | "
            "<cyan>{name}</cyan>:"
            "<cyan>{function}</cyan>:"
            "<cyan>{line}</cyan> | "
            "<level>{message}</level>"
        ),
    )

    # Application log
    logger.add(
        LOG_DIRECTORY / "application.log",
        rotation="10 MB",
        retention="30 days",
        compression="zip",
        level="INFO",
        enqueue=True,
    )

    # Error log
    logger.add(
        LOG_DIRECTORY / "error.log",
        rotation="10 MB",
        retention="90 days",
        compression="zip",
        level="ERROR",
        enqueue=True,
        backtrace=True,
        diagnose=settings.DEBUG,
    )


def get_logger():
    """
    Return configured logger.
    """
    return logger