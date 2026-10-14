import json
from datetime import date
from types import SimpleNamespace
import pytest
from fastapi import HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from app.database.base import Base
from app.services.ai import structured_itinerary as plans
from app.services.ai.itinerary_models import ItineraryDraft
from app.modules.country.model import Country
from app.modules.state.model import State
from app.modules.city.model import City
from app.modules.place.model import Place
from app.modules.trips.model import Trip
from app.modules.itinerary.model import ItineraryDay, ItineraryItem
from app.services.discovery.nearby import search, NearbyRequest


async def fixture():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as con:
        await con.run_sync(Base.metadata.create_all)
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    async with sessions() as db:
        db.add(
            Country(
                id="country",
                name="India",
                iso2="IN",
                iso3="IND",
                phone_code="91",
                currency_code="INR",
                currency_name="Rupee",
                capital="Delhi",
                continent="Asia",
                timezone="Asia/Kolkata",
            )
        )
        db.add(State(id="state", country_id="country", name="Maharashtra", code="MH"))
        db.add(
            City(
                id="city",
                country_id="country",
                state_id="state",
                name="Pune",
                latitude=18.52,
                longitude=73.85,
            )
        )
        db.add(
            Place(
                id="museum",
                city_id="city",
                name="Museum",
                slug="museum",
                place_type="museum",
                latitude=18.52,
                longitude=73.85,
            )
        )
        await db.commit()
    return engine, sessions


@pytest.mark.asyncio
async def test_preview_review_atomic_save_and_idempotency(monkeypatch):
    engine, sessions = await fixture()

    async def provider(*args, **kwargs):
        assert args == ("generate",)
        return (
            SimpleNamespace(
                provider="groq",
                content=json.dumps(
                    {
                        "title": "Pune days",
                        "summary": "A relaxed day",
                        "days": [
                            {
                                "title": "Explore",
                                "activities": [
                                    {
                                        "title": "Museum",
                                        "place_id": "museum",
                                        "kind": "activity",
                                        "duration_minutes": 90,
                                    },
                                    {"title": "Rest", "kind": "rest"},
                                ],
                            }
                        ],
                    }
                ),
            ),
            "",
            ["groq"],
        )

    monkeypatch.setattr(plans.free_runtime, "run", provider)
    request = plans.GeneratePlan(
        city_id="city",
        start_date=date(2026, 10, 20),
        end_date=date(2026, 10, 20),
        currency="USD",
        budget_amount=100,
    )
    async with sessions() as db:
        draft = await plans.generate(db, "owner", request)
        assert await db.scalar(select(func.count()).select_from(Trip)) == 0
        with pytest.raises(HTTPException):
            await plans.save(
                db, "other", draft["id"], plans.SavePlan(title="Trip", selected=["0:0"])
            )
        await db.rollback()
        place = await db.get(Place, "museum")
        place.is_active = False
        await db.commit()
        with pytest.raises(HTTPException):
            await plans.save(
                db, "owner", draft["id"], plans.SavePlan(title="Trip", selected=["0:0"])
            )
        assert await db.scalar(select(func.count()).select_from(Trip)) == 0
        place = await db.get(Place, "museum")
        place.is_active = True
        await db.commit()
        result = await plans.save(
            db,
            "owner",
            draft["id"],
            plans.SavePlan(title="My reviewed plan", selected=["0:0"]),
        )
        again = await plans.save(
            db, "owner", draft["id"], plans.SavePlan(title="Retry", selected=["0:0"])
        )
        assert result["trip_id"] == again["trip_id"] and again["already_saved"]
        assert await db.scalar(select(func.count()).select_from(ItineraryDay)) == 1
        item = await db.scalar(select(ItineraryItem))
        assert item.place_id == "museum" and float(item.latitude) == 18.52
        trip = await db.get(Trip, result["trip_id"])
        assert trip.budget_currency == "USD" and float(trip.budget_amount) == 100
    await engine.dispose()


@pytest.mark.asyncio
async def test_ai_unknown_places_and_nearby_privacy(monkeypatch):
    engine, sessions = await fixture()

    async def bad(*args, **kwargs):
        return (
            SimpleNamespace(
                provider="groq",
                content=json.dumps(
                    {
                        "title": "Bad plan",
                        "days": [
                            {
                                "title": "Day",
                                "activities": [
                                    {"title": "Invented", "place_id": "not-real"}
                                ],
                            }
                        ],
                    }
                ),
            ),
            "",
            ["groq"],
        )

    monkeypatch.setattr(plans.free_runtime, "run", bad)
    async with sessions() as db:
        with pytest.raises(HTTPException) as exc:
            await plans.generate(
                db,
                "owner",
                plans.GeneratePlan(
                    city_id="city",
                    start_date=date(2026, 10, 20),
                    end_date=date(2026, 10, 20),
                ),
            )
        assert exc.value.status_code == 502
        assert await db.scalar(select(func.count()).select_from(ItineraryDraft)) == 0
        nearby = await search(
            db, NearbyRequest(latitude=18.52, longitude=73.85), enrich=False
        )
        assert (
            nearby["items"][0]["name"] == "Museum"
            and nearby["items"][0]["distance_km"] == 0
        )
        assert "origin" not in nearby
        nearby = await search(
            db,
            NearbyRequest(latitude=18.52, longitude=73.85, kind="restaurant"),
            enrich=False,
        )
        assert nearby["items"] == []
        country = await db.get(Country, "country")
        country.is_active = False
        await db.commit()
        assert (
            await search(
                db, NearbyRequest(latitude=18.52, longitude=73.85), enrich=False
            )
        )["items"] == []
    await engine.dispose()


@pytest.mark.asyncio
async def test_save_rolls_back_failure_after_trip_and_day_insert(monkeypatch):
    engine, sessions = await fixture()
    async with sessions() as db:
        row = ItineraryDraft(
            user_id="owner",
            city_id="city",
            expires_at=plans.now() + plans.timedelta(hours=24),
            content_json=json.dumps(
                {
                    "request": {
                        "city_id": "city",
                        "start_date": "2026-10-20",
                        "end_date": "2026-10-20",
                    },
                    "plan": {
                        "title": "Reviewed trip",
                        "days": [
                            {
                                "title": "Day one",
                                "activities": [{"title": "Rest", "kind": "rest"}],
                            }
                        ],
                    },
                    "places": {},
                }
            ),
        )
        db.add(row)
        await db.commit()
        ident = row.id
        original_flush = db.flush
        calls = 0

        async def fail_midway(*args, **kwargs):
            nonlocal calls
            calls += 1
            await original_flush(*args, **kwargs)
            if calls == 3:
                assert await db.scalar(select(func.count()).select_from(Trip)) == 1
                assert (
                    await db.scalar(select(func.count()).select_from(ItineraryDay)) == 1
                )
                raise RuntimeError("Injected failure after day insert")

        monkeypatch.setattr(db, "flush", fail_midway)
        with pytest.raises(HTTPException) as exc:
            await plans.save(
                db,
                "owner",
                ident,
                plans.SavePlan(title="Reviewed trip", selected=["0:0"]),
            )
        assert exc.value.status_code == 409
        monkeypatch.setattr(db, "flush", original_flush)
        assert await db.scalar(select(func.count()).select_from(Trip)) == 0
        assert await db.scalar(select(func.count()).select_from(ItineraryDay)) == 0
        assert (await db.get(ItineraryDraft, ident)).trip_id is None
        result = await plans.save(
            db, "owner", ident, plans.SavePlan(title="Reviewed trip", selected=["0:0"])
        )
        assert result["trip_id"]
    await engine.dispose()


def test_additive_draft_migration_preserves_existing_trips(monkeypatch):
    import importlib.util
    from pathlib import Path
    import sqlalchemy as sa
    from alembic.operations import Operations
    from alembic.migration import MigrationContext

    path = (
        Path(__file__).parents[1]
        / "alembic/versions/d37f82ca0b79_ai_itinerary_drafts.py"
    )
    spec = importlib.util.spec_from_file_location("draft_migration", path)
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    engine = sa.create_engine("sqlite:///:memory:")
    with engine.begin() as conn:
        conn.execute(sa.text("CREATE TABLE existing_trips (title TEXT)"))
        conn.execute(sa.text("INSERT INTO existing_trips VALUES ('Keep me')"))
        monkeypatch.setattr(
            migration, "op", Operations(MigrationContext.configure(conn))
        )
        migration.upgrade()
        conn.execute(
            sa.text(
                "INSERT INTO ai_itinerary_drafts (id,user_id,city_id,content_json,expires_at) VALUES ('1','owner','city','{}','2026-10-20')"
            )
        )
        assert (
            conn.execute(sa.text("SELECT created_at FROM ai_itinerary_drafts")).scalar()
            is not None
        )
        assert (
            conn.execute(sa.text("SELECT title FROM existing_trips")).scalar()
            == "Keep me"
        )
        migration.downgrade()
        assert (
            conn.execute(sa.text("SELECT title FROM existing_trips")).scalar()
            == "Keep me"
        )
    engine.dispose()
