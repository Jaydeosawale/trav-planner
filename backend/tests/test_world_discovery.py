import json
from datetime import timedelta
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from fastapi import HTTPException
from app.services.discovery import world
from app.services.discovery.imports import OSMPack, import_pack
from app.modules.country.model import Country
from app.modules.state.model import State
from app.modules.city.model import City
from app.modules.place.model import Place


@pytest.mark.asyncio
async def test_cache_preservation_promotion_and_limits(monkeypatch):
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as c:
        for table in [
            Country.__table__,
            State.__table__,
            City.__table__,
            Place.__table__,
            world.DiscoveryCache.__table__,
            world.DiscoveryBudget.__table__,
        ]:
            await c.run_sync(lambda con, table=table: table.create(con))
    sessions = async_sessionmaker(engine, expire_on_commit=False, autoflush=False)
    monkeypatch.setattr(world, "SessionLocal", sessions)
    calls = []
    ident = world.uid("wikidata:Q1234")
    item = dict(
        id=ident,
        city_id="city",
        name="Verified museum",
        slug="wd-q1234",
        place_type="museum",
        description="Source description",
        latitude=48.85,
        longitude=2.35,
        provider="wikidata",
        external_place_id="Q1234",
        image_url=None,
        image_credit=None,
        visiting_notes="Check current hours.",
        is_active=True,
        is_discovery=True,
    )

    async def fetch(*args):
        calls.append(args)
        return [dict(item)]

    monkeypatch.setattr(world, "wikidata", fetch)
    async with sessions() as db:
        db.add(
            City(
                id="city",
                country_id="country",
                state_id="state",
                name="Paris",
                latitude=48.85,
                longitude=2.35,
                is_active=True,
                is_deleted=False,
            )
        )
        await db.commit()
        first = await world.discover(db, "city", "museum")
        assert first["items"][0]["id"] == ident
        await world.discover(db, "city", "museum")
        assert len(calls) == 1
        promoted = await world.resolve(db, ident)
        assert promoted.is_discovery
        assert (await world.resolve(db, ident)).id == ident
        promoted.description = "Admin edit"
        promoted.image_url = None
        await db.commit()
        assert (await world.discover(db, "city", "museum"))["items"][0][
            "description"
        ] == "Admin edit"
        promoted.is_active = False
        await db.commit()
        assert (await world.discover(db, "city", "museum"))["items"] == []
        with pytest.raises(HTTPException):
            await world.resolve(db, ident)
        pack = OSMPack(
            city_id="city",
            license="ODbL-1.0",
            items=[
                dict(
                    external_id="node/123",
                    name="Real Cafe",
                    place_type="cafe",
                    latitude=48.85,
                    longitude=2.35,
                )
            ],
        )
        await import_pack(db, pack)
        assert (await world.discover(db, "city", "cafe"))["items"][0][
            "name"
        ] == "Real Cafe"
        from app.services.discovery.router import nearby_food

        nearby = await nearby_food(
            world.uid("osm:node/123"), radius_km=2, db=db, user=None
        )
        assert [(p["name"], p["distance_km"]) for p in nearby["items"]] == [
            ("Real Cafe", 0.0)
        ]
        assert (
            len(calls) == 1
        )  # Nearby food uses stored data, never a paid/source call.
        bad = OSMPack(
            city_id="city",
            license="ODbL-1.0",
            items=[
                dict(
                    external_id="node/999",
                    name="Far Cafe",
                    place_type="cafe",
                    latitude=0,
                    longitude=0,
                )
            ],
        )
        with pytest.raises(HTTPException):
            await import_pack(db, bad)
        assert await db.get(world.DiscoveryCache, world.uid("osm:node/999")) is None
        monkeypatch.setattr(world, "MAX_CACHE_BYTES", 1)
        with pytest.raises(RuntimeError):
            await world.cache_put(
                db, "too-big", "candidate", {"x": "data"}, timedelta(days=1)
            )
        await db.rollback()
    async with sessions() as db:
        await world.cache_put(
            db,
            "settings",
            "settings",
            {"enabled": True, "daily_calls": 1},
            timedelta(days=1),
        )
        await db.commit()
    await world.reserve()
    with pytest.raises(RuntimeError):
        await world.reserve()
    await engine.dispose()


@pytest.mark.asyncio
async def test_source_failure_is_cached_and_photo_requires_license(monkeypatch):
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as c:
        for table in [
            Country.__table__,
            State.__table__,
            City.__table__,
            Place.__table__,
            world.DiscoveryCache.__table__,
            world.DiscoveryBudget.__table__,
        ]:
            await c.run_sync(lambda con, table=table: table.create(con))
    sessions = async_sessionmaker(engine, expire_on_commit=False)

    async def fail(*args):
        raise TimeoutError()

    monkeypatch.setattr(world, "wikidata", fail)
    async with sessions() as db:
        db.add(
            City(
                id="city",
                country_id="c",
                state_id="s",
                name="City",
                latitude=0,
                longitude=0,
                is_active=True,
                is_deleted=False,
            )
        )
        await db.commit()
        assert (await world.discover(db, "city"))["status"] == "unavailable"
        item = {"id": "candidate", "city_id": "city", "image_filename": "Example.jpg"}
        await world.cache_put(db, "candidate", "candidate", item, timedelta(days=1))
        await db.commit()

        async def unlicensed(*args, **kwargs):
            return {
                "query": {
                    "pages": {
                        "1": {
                            "imageinfo": [
                                {
                                    "thumburl": "https://upload.wikimedia.org/test.jpg",
                                    "extmetadata": {
                                        "LicenseShortName": {
                                            "value": "All rights reserved"
                                        },
                                        "Artist": {"value": "Author"},
                                    },
                                }
                            ]
                        }
                    }
                }
            }

        monkeypatch.setattr(world, "request_json", unlicensed)
        assert not (await world.photo(db, "candidate")).get("image_url")

        fallback = {"id": "fallback", "city_id": "city", "wikipedia_title": "Museum"}
        await world.cache_put(db, "fallback", "candidate", fallback, timedelta(days=1))
        await db.commit()
        source_calls = []

        async def licensed(url, params, **kwargs):
            source_calls.append(url)
            if "en.wikipedia.org" in url:
                assert params["pilicense"] == "free"
                return {"query": {"pages": {"1": {"pageimage": "Museum.jpg"}}}}
            return {
                "query": {
                    "pages": {
                        "2": {
                            "imageinfo": [
                                {
                                    "thumburl": "https://thumb.wikimedia.org/museum.jpg",
                                    "descriptionurl": "https://commons.wikimedia.org/wiki/File:Museum.jpg",
                                    "extmetadata": {
                                        "LicenseShortName": {"value": "CC BY 4.0"},
                                        "Artist": {"value": "Creator"},
                                        "LicenseUrl": {
                                            "value": "https://creativecommons.org/licenses/by/4.0/"
                                        },
                                    },
                                }
                            ]
                        }
                    }
                }
            }

        monkeypatch.setattr(world, "request_json", licensed)
        assert (await world.photo(db, "fallback"))["image_url"].endswith("museum.jpg")
        await world.photo(db, "fallback")
        assert (
            len(source_calls) == 2
        )  # Licensed result is cached; no repeat source calls.
    await engine.dispose()


@pytest.mark.asyncio
async def test_admin_endpoints_reject_learner_and_oversized_quota(monkeypatch):
    from fastapi import FastAPI
    from fastapi.responses import JSONResponse
    from httpx import AsyncClient, ASGITransport
    from types import SimpleNamespace
    from app.services.discovery.router import router
    from app.dependencies.current_user import get_current_user
    from app.database.session import get_db
    from app.common.exceptions.app_exception import AppException

    app = FastAPI()
    app.include_router(router, prefix="/discovery")

    @app.exception_handler(AppException)
    async def denied(request, exc):
        return JSONResponse(status_code=exc.status_code, content={"error": "Denied"})

    app.dependency_overrides[get_current_user] = lambda: SimpleNamespace(
        id="learner", role="user"
    )

    async def db():
        yield None

    app.dependency_overrides[get_db] = db
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        for path in ["/admin/status", "/admin/candidates"]:
            assert (await client.get("/discovery" + path)).status_code == 403
        assert (
            await client.put(
                "/discovery/admin/settings", json={"enabled": True, "daily_calls": 200}
            )
        ).status_code == 403
        assert (
            await client.post("/discovery/admin/candidates/x/publish")
        ).status_code == 403
        app.dependency_overrides[get_current_user] = lambda: SimpleNamespace(
            id="admin", role="admin"
        )
        assert (
            await client.put("/discovery/admin/settings", json={"daily_calls": 201})
        ).status_code == 422


def test_discovery_migration_preserves_existing_tables(monkeypatch):
    from pathlib import Path
    import importlib.util
    import sqlalchemy as sa
    from alembic.operations import Operations
    from alembic.migration import MigrationContext

    path = (
        Path(__file__).parents[1] / "alembic/versions/c26f71b9ea68_discovery_cache.py"
    )
    spec = importlib.util.spec_from_file_location("discovery_migration", path)
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    engine = sa.create_engine("sqlite:///:memory:")
    with engine.begin() as conn:
        conn.execute(sa.text("CREATE TABLE saved_trips (title TEXT)"))
        conn.execute(sa.text("INSERT INTO saved_trips VALUES ('Preserve')"))
        monkeypatch.setattr(
            migration, "op", Operations(MigrationContext.configure(conn))
        )
        migration.upgrade()
        assert "discovery_cache" in sa.inspect(conn).get_table_names()
        assert (
            conn.execute(sa.text("SELECT title FROM saved_trips")).scalar()
            == "Preserve"
        )
    engine.dispose()


@pytest.mark.asyncio
async def test_general_attraction_search_retains_specific_source_category(monkeypatch):
    calls = []
    async def source(url, params, **kwargs):
        calls.append(url)
        if "sparql" in url:
            assert "?root" in params["query"]
            return {"results": {"bindings": [{"item": {"value": "http://www.wikidata.org/entity/Q123"},
                "root": {"value": "http://www.wikidata.org/entity/Q22698"}}]}}
        return {"entities": {"Q123": {"labels": {"en": {"value": "Local park"}},
            "claims": {"P625": [{"mainsnak": {"datavalue": {"value": {
                "latitude": 18.52, "longitude": 73.85, "globe": "http://www.wikidata.org/entity/Q2"}}}}]}}}}
    monkeypatch.setattr(world, "request_json", source)
    items = await world.wikidata("city", 18.52, 73.85, "attraction")
    assert items[0]["place_type"] == "park" and len(calls) == 2
