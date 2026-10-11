"""
Alembic environment configuration.

Supports SQLAlchemy 2.x and the Trav Planner backend.
"""

from __future__ import annotations

from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import create_async_engine

from app.core.settings import settings
from app.database.base import Base
from app.database.connection import database_connection_options

# ---------------------------------------------------------
# IMPORTANT
# Import all SQLAlchemy models so Base.metadata
# contains every table.
# ---------------------------------------------------------

import app.database.models  # noqa: F401


# ==========================================================
# Alembic Config
# ==========================================================

config = context.config


# ==========================================================
# Logging
# ==========================================================

if config.config_file_name is not None:
    fileConfig(config.config_file_name)


# ==========================================================
# Metadata
# ==========================================================

target_metadata = Base.metadata


# ==========================================================
# Database URL
# ==========================================================

database_url = settings.database_url


# ==========================================================
# Offline
# ==========================================================

def run_migrations_offline() -> None:
    """
    Run migrations in offline mode.
    """

    context.configure(
        url=database_url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,
        compare_server_default=True,
        dialect_opts={
            "paramstyle": "named",
        },
    )

    with context.begin_transaction():
        context.run_migrations()


# ==========================================================
# Migration callback
# ==========================================================

def do_run_migrations(connection: Connection) -> None:
    """
    Run Alembic migrations using a synchronous
    connection supplied by the async engine.
    """

    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
        compare_server_default=True,
    )

    with context.begin_transaction():
        context.run_migrations()


# ==========================================================
# Online
# ==========================================================

def run_migrations_online() -> None:
    """
    Run migrations in online mode using
    SQLAlchemy's async engine.
    """

    engine_url, connect_args = database_connection_options(database_url)
    connectable = create_async_engine(
        engine_url,
        connect_args=connect_args,
        poolclass=pool.NullPool,
    )

    async def run_async_migrations() -> None:
        async with connectable.connect() as connection:
            await connection.run_sync(
                do_run_migrations
            )

        await connectable.dispose()

    import asyncio

    asyncio.run(run_async_migrations())


# ==========================================================
# Entry
# ==========================================================

if context.is_offline_mode():
    run_migrations_offline()
else:
     run_migrations_online()