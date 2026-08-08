"""
Seed Runner.
"""

from __future__ import annotations

import asyncio
import sys

from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import SessionLocal

# Import seeders so they register themselves
from seeds.loaders.country_seeder import CountrySeeder  # noqa: F401
from seeds.loaders.state_seeder import StateSeeder  # noqa: F401
from seeds.loaders.city_seeder import CitySeeder  # noqa: F401

from seeds.utils.registry import SeederRegistry


async def run_seeder(
    db: AsyncSession,
    name: str,
) -> None:
    """
    Run a single registered seeder.
    """

    seeder_cls = SeederRegistry.get(name)

    if seeder_cls is None:
        available = ", ".join(
            SeederRegistry.all().keys()
        )

        raise ValueError(
            f"Unknown seeder '{name}'. "
            f"Available seeders: {available}"
        )

    await seeder_cls(db).run()


async def run_all(
    db: AsyncSession,
) -> None:
    """
    Run all registered seeders.
    """

    for seeder_cls in SeederRegistry.all().values():
        await seeder_cls(db).run()


async def main() -> None:
    """
    Seed application entry point.
    """

    async with SessionLocal() as db:

        if len(sys.argv) == 1:
            await run_all(db)
            return

        await run_seeder(
            db,
            sys.argv[1].lower(),
        )


if __name__ == "__main__":
    asyncio.run(main())