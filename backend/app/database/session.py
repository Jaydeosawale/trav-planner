"""
Database session configuration.
"""

from __future__ import annotations

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.settings import settings
from app.database.connection import database_connection_options


# ------------------------------------------------------------------
# Async Engine
# ------------------------------------------------------------------

database_url, connect_args = database_connection_options(settings.database_url)

engine = create_async_engine(
    database_url,
    connect_args=connect_args,
    echo=settings.DEBUG,
    future=True,
    pool_pre_ping=True,
    pool_recycle=3600,
    pool_size=5,
    max_overflow=5,
)


# ------------------------------------------------------------------
# Session Factory
# ------------------------------------------------------------------

SessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)


# ------------------------------------------------------------------
# Dependency
# ------------------------------------------------------------------

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    FastAPI dependency.

    Provides a database session.

    Automatically closes the session.
    """

    async with SessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


# ------------------------------------------------------------------
# Engine Shutdown
# ------------------------------------------------------------------

async def close_engine() -> None:
    """
    Gracefully dispose database connections.
    """

    await engine.dispose()


# ------------------------------------------------------------------
# Register all SQLAlchemy models
# ------------------------------------------------------------------

from app.database import models as _models  # noqa: E402,F401