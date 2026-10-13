"""Offline worldwide town search; selected locations alone become app cities."""

import atexit
from contextlib import closing
import gzip
import json
import os
import sqlite3
import tempfile
import time
from functools import lru_cache
from pathlib import Path
from fastapi import HTTPException
from sqlalchemy import select, func, text
from seeds.bootstrap_catalogue import stable_id
from seeds.bootstrap_geography import STARTER_IDS
from seeds.build_location_index import normalize
from app.modules.city.model import City
from app.modules.country.model import Country
from app.modules.state.model import State
from app.services.discovery.world import stats, MAX_DB_BYTES

SOURCE = Path(__file__).resolve().parents[3] / "seeds/data/geonames_towns.sqlite.gz"


@lru_cache(maxsize=1)
def prepare():
    # Deployment-local disk; no storage account, external API or database bulk load.
    with tempfile.NamedTemporaryFile(
        prefix="trav-towns-", suffix=".sqlite", delete=False
    ) as out:
        path = Path(out.name)
        try:
            with gzip.open(SOURCE, "rb") as source:
                total = 0
                while chunk := source.read(1024 * 1024):
                    total += len(chunk)
                    if total > 64 * 1024 * 1024:
                        raise ValueError("Offline index exceeds size guard")
                    out.write(chunk)
        except Exception:
            path.unlink(missing_ok=True)
            raise
    os.chmod(path, 0o400)
    return path


def cleanup():
    if prepare.cache_info().currsize:
        prepare().unlink(missing_ok=True)
        prepare.cache_clear()


atexit.register(cleanup)


def connection():
    db = sqlite3.connect(f"file:{prepare()}?mode=ro&immutable=1", uri=True)
    db.row_factory = sqlite3.Row
    deadline = time.monotonic() + 1
    db.set_progress_handler(lambda: int(time.monotonic() > deadline), 1000)
    return db


def search(query, country=None):
    q = normalize(query)
    if not 2 <= len(q) <= 80:
        return []
    with closing(connection()) as db:
        rows = db.execute(
            """SELECT l.* FROM names n JOIN locations l ON l.id=n.id
            WHERE n.name>=? AND n.name<? AND (? IS NULL OR l.country=?)
            GROUP BY l.id ORDER BY MAX(n.name=?) DESC,l.population DESC,l.id LIMIT 20""",
            (q, q + "\U0010ffff", country, country, q),
        ).fetchall()
        return [dict(r) for r in rows]


def record(ident):
    if not ident.isdigit() or len(ident) > 12:
        raise HTTPException(422, "Invalid location identity.")
    with closing(connection()) as db:
        row = db.execute("SELECT * FROM locations WHERE id=?", (ident,)).fetchone()
        if row is None:
            raise HTTPException(404, "Location not found.")
        return dict(row)


def metadata():
    with closing(connection()) as db:
        return json.loads(db.execute("SELECT value FROM metadata").fetchone()[0])


async def require_available(db, city):
    country = await db.get(Country, city.country_id)
    state = await db.get(State, city.state_id)
    if (
        city.is_deleted
        or not city.is_active
        or country is None
        or state is None
        or country.is_deleted
        or not country.is_active
        or state.is_deleted
        or not state.is_active
    ):
        raise HTTPException(404, "Location unavailable.")
    return city


async def resolve_location(db, source):
    ident = source["id"]
    city_id = stable_id("city", STARTER_IDS.get(ident, "geonames:" + ident))
    if db.bind.dialect.name == "postgresql":
        await db.execute(text("SELECT pg_advisory_xact_lock(20261013, 9)"))
    existing = await db.get(City, city_id)
    if existing:
        return await require_available(db, existing)
    usage = await stats(db)
    count = await db.scalar(select(func.count()).select_from(City))
    # Bounded total city count; never import the whole index.
    if count >= 45000 or (
        usage["database_bytes"] is not None and usage["database_bytes"] >= MAX_DB_BYTES
    ):
        raise HTTPException(
            409,
            "Free location storage limit reached. Existing destinations remain available.",
        )
    country = await db.scalar(select(Country).where(Country.iso2 == source["country"]))
    if country is None or country.is_deleted or not country.is_active:
        raise HTTPException(404, "Country unavailable.")
    state_id = stable_id("state", "geonames:" + source["region"])
    state = await db.get(State, state_id)
    if state is None:
        state = await db.scalar(
            select(State).where(
                State.country_id == country.id,
                State.code == "GN:" + source["region"].split(".", 1)[1],
            )
        )
    if state is None:
        # Starter cities use reviewed region identities rather than GeoNames codes.
        for gn, qid in STARTER_IDS.items():
            starter = record(gn)
            if starter["region"] == source["region"]:
                original = await db.get(City, stable_id("city", qid))
                if original:
                    state = await db.get(State, original.state_id)
                break
    if state is None:
        state = State(
            id=state_id,
            country_id=country.id,
            code="GN:" + source["region"].split(".", 1)[1],
            name=source["region_name"],
            is_active=True,
        )
        db.add(state)
        await db.flush()
    if state.is_deleted or not state.is_active:
        raise HTTPException(404, "Region unavailable.")
    existing = await db.scalar(
        select(City).where(City.state_id == state.id, City.name == source["name"])
    )
    if existing:
        return await require_available(db, existing)
    city = City(
        id=city_id,
        country_id=country.id,
        state_id=state.id,
        name=source["name"],
        latitude=source["latitude"],
        longitude=source["longitude"],
        is_active=True,
    )
    db.add(city)
    await db.commit()
    return city
