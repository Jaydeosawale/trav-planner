"""One bounded source sample; no network calls at deployment."""

import asyncio, json
from datetime import date, timedelta
from pathlib import Path
from fastapi import HTTPException
from app.database.session import SessionLocal, engine
from app.services.discovery.world import DiscoveryCache, cache_put
from app.services.discovery.imports import OSMPack, import_pack


async def bootstrap(db):
    source = json.loads(
        (Path(__file__).parent / "data/monaco_osm_starter.json").read_text()
    )
    if date.fromisoformat(source["checked_on"]) < date.today() - timedelta(days=30):
        return "Source sample expired; refresh through admin imports."
    key = "import:monaco:" + source["checked_on"]
    if await db.get(DiscoveryCache, key):
        return "Source sample already applied."
    try:
        result = await import_pack(db, OSMPack.model_validate(source["pack"]))
        await cache_put(db, key, "settings", result, timedelta(days=36500))
        await db.commit()
        return f"Added {result['imported']} source candidates for review."
    except (RuntimeError, HTTPException):
        await db.rollback()
        return "Optional regional sample skipped; existing places preserved."


async def main():
    try:
        async with SessionLocal() as db:
            print(await bootstrap(db))
    finally:
        await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
