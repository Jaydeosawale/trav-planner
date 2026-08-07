"""
Alembic environment configuration.

Supports SQLAlchemy 2.x and the Trav Planner backend.
"""

from __future__ import annotations

from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

from app.core.settings import settings
from app.database.base import Base

# ---------------------------------------------------------
# IMPORTANT
# Import all SQLAlchemy models so Base.metadata
# contains every table.
# ---------------------------------------------------------
import app.database.models

# ==========================================================
# Alembic Config
# ==========================================================

config = context.config

# ----------------------------------------------------------
# Alembic uses synchronous psycopg.
# Application uses asyncpg.
# ----------------------------------------------------------

sync_database_url = settings.database_url.replace(
    "+asyncpg",
    "+psycopg",
)

config.set_main_option(
    "sqlalchemy.url",
    sync_database_url,
)

# ----------------------------------------------------------
# Logging
# ----------------------------------------------------------

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# ----------------------------------------------------------
# Metadata
# ----------------------------------------------------------

target_metadata = Base.metadata


# ==========================================================
# Offline
# ==========================================================

def run_migrations_offline() -> None:
    """
    Run migrations in offline mode.
    """

    context.configure(
        url=sync_database_url,
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
# Online
# ==========================================================

def run_migrations_online() -> None:
    """
    Run migrations in online mode.
    """

    configuration = config.get_section(
        config.config_ini_section,
        {},
    )

    configuration["sqlalchemy.url"] = sync_database_url

    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            compare_server_default=True,
        )

        with context.begin_transaction():
            context.run_migrations()


# ==========================================================
# Entry
# ==========================================================

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()