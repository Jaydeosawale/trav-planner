import pytest
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from fastapi import HTTPException
from app.services.discovery import locations
from app.modules.country.model import Country
from app.modules.state.model import State
from app.modules.city.model import City
from app.services.discovery.models import DiscoveryCache, DiscoveryBudget


def test_offline_world_search():
    assert locations.metadata()["records"] > 200000
    assert locations.metadata()["license"] == "CC-BY-4.0"
    assert locations.search("wai", "IN")[0]["name"] == "Wai"
    assert locations.search("panchgani", "IN")[0]["latitude"] > 17
    assert locations.search("paris", "FR")[0]["name"] == "Paris"
    assert locations.search("xxzznonexistent") == []
    assert locations.search("  ") == []
    assert len(locations.search("sa")) <= 20
    with pytest.raises(HTTPException):
        locations.record("../../etc/passwd")


@pytest.mark.asyncio
async def test_open_preserves_edits_and_disabled_locations():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as c:
        for table in [
            Country.__table__,
            State.__table__,
            City.__table__,
            DiscoveryCache.__table__,
            DiscoveryBudget.__table__,
        ]:
            await c.run_sync(lambda con, table=table: table.create(con))
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    source = locations.search("panchgani", "IN")[0]
    async with sessions() as db:
        db.add(
            Country(
                id="india",
                iso2="IN",
                iso3="IND",
                name="India",
                phone_code="91",
                currency_code="INR",
                currency_name="Rupee",
                capital="New Delhi",
                continent="Asia",
                timezone="Asia/Kolkata",
                is_active=True,
                is_deleted=False,
            )
        )
        await db.commit()
        city = await locations.resolve_location(db, source)
        city.name = "Admin changed name"
        await db.commit()
        assert (
            await locations.resolve_location(db, source)
        ).name == "Admin changed name"
        city.is_active = False
        await db.commit()
        with pytest.raises(HTTPException):
            await locations.resolve_location(db, source)
    await engine.dispose()
