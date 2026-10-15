from datetime import timedelta
import pytest
from app.services.discovery import open_map, world
from app.tools.destination_discovery import DestinationDiscoveryTool
from test_structured_itinerary import fixture


@pytest.mark.asyncio
async def test_fixed_public_area_query_and_unverified_tags(monkeypatch):
    calls = []

    async def source(url, params, **kwargs):
        calls.append((url, params, kwargs))
        return {
            "elements": [
                {
                    "type": "node",
                    "id": 1,
                    "lat": 18.52,
                    "lon": 73.85,
                    "tags": {
                        "name": "Small Café",
                        "amenity": "cafe",
                        "opening_hours": "Mo-Fr 08:00-20:00",
                        "cuisine": "coffee_shop",
                        "image": "https://untrusted.invalid/x.jpg",
                    },
                },
                {
                    "type": "way",
                    "id": 2,
                    "center": {"lat": 18.521, "lon": 73.851},
                    "tags": {"name": "Local Shop", "shop": "convenience"},
                },
                {
                    "type": "node",
                    "id": 3,
                    "lat": 18.52,
                    "lon": 73.85,
                    "tags": {"name": "Private", "access": "private"},
                },
                {
                    "type": "node",
                    "id": 4,
                    "lat": 80,
                    "lon": 30,
                    "tags": {"name": "Wrong area"},
                },
                {
                    "type": "node",
                    "id": 5,
                    "lat": float("nan"),
                    "lon": 73.85,
                    "tags": {"name": "Invalid"},
                },
            ]
        }

    monkeypatch.setattr(world, "request_json", source)
    items = await open_map.fetch("city", 18.52, 73.85, "all")
    assert len(items) == 2 and items[0]["place_type"] == "cafe"
    assert "unverified" in items[0]["description"] and items[0]["image_url"] is None
    assert "ODbL-1.0" in items[0]["visiting_notes"]
    assert calls[0][0] == open_map.ENDPOINT and calls[0][2]["method"] == "GET"
    assert (
        "around:5000,18.52,73.85" in calls[0][1]["data"]
        and "out center 80" in calls[0][1]["data"]
    )
    assert items[0]["id"] == world.uid("osm:node/1")
    with pytest.raises(ValueError):
        await open_map.fetch("city", 18.52, 73.85, "x]; malicious")


@pytest.mark.asyncio
async def test_local_discovery_cached_and_admin_hide_preserved(monkeypatch):
    engine, sessions = await fixture()
    calls = []

    async def source(city_id, lat, lon, kind):
        calls.append(kind)
        return [
            {
                "id": world.uid("osm:node/1"),
                "city_id": city_id,
                "name": "Café",
                "place_type": "cafe",
                "provider": "osm",
                "external_place_id": "node/1",
                "latitude": lat,
                "longitude": lon,
                "is_active": True,
                "is_discovery": True,
                "slug": "osm-node-1",
            }
        ]

    monkeypatch.setattr(open_map, "fetch", source)
    async with sessions() as db:
        first = await world.discover(db, "city", "cafe")
        again = await world.discover(db, "city", "cafe")
        assert first["items"][0]["name"] == "Café" and len(calls) == 1
        assert len(again["items"]) == 1
        from app.modules.place.model import Place

        db.add(
            Place(
                id=first["items"][0]["id"],
                city_id="city",
                name="Hidden",
                slug="hidden",
                place_type="cafe",
                provider="osm",
                external_place_id="node/1",
                is_active=False,
            )
        )
        await db.commit()
        assert (await world.discover(db, "city", "cafe"))["items"] == []
        from app.modules.country.model import Country

        country = await db.get(Country, "country")
        country.is_active = False
        await db.commit()
        result = await DestinationDiscoveryTool().execute(
            db=db, city_name="Pune", kind="cafe"
        )
        assert result["items"] == [] and len(calls) == 1
    await engine.dispose()


@pytest.mark.asyncio
async def test_agent_resolves_only_exact_unique_town(monkeypatch):
    from app.tools import destination_discovery as tools
    from app.services.discovery import locations
    from app.modules.city.model import City

    engine, sessions = await fixture()
    resolved = []
    monkeypatch.setattr(
        locations,
        "search",
        lambda q, c: [{"id": "123", "name": "Tiny Town", "country": "IN"}],
    )

    async def resolve(db, source):
        resolved.append(source["id"])
        return await db.get(City, "city")

    async def discovery(db, city_id, kind):
        return {"items": [], "message": "No mapped listings yet"}

    monkeypatch.setattr(locations, "resolve_location", resolve)
    monkeypatch.setattr(tools, "discover", discovery)
    async with sessions() as db:
        await tools.DestinationDiscoveryTool().execute(
            db=db, city_name="Tiny", country_code="IN"
        )
        assert resolved == []
        await tools.DestinationDiscoveryTool().execute(
            db=db, city_name="Tiny Town", country_code="IN"
        )
        assert resolved == ["123"]
    await engine.dispose()
