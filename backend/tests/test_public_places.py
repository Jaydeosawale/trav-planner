"""Public discovery must reach places, without authentication or planner routes."""

from unittest.mock import AsyncMock, patch

from fastapi.testclient import TestClient

from app.database.session import get_db
from app.main import app


def test_public_place_search_is_mounted_and_anonymous():
    async def fake_db():
        yield object()

    app.dependency_overrides[get_db] = fake_db
    try:
        with patch(
            "app.modules.place.router.service.search", new_callable=AsyncMock
        ) as search:
            search.return_value = ([], 0)
            response = TestClient(app).get(
                "/api/v1/places/search?city_id=pune&size=100"
            )
            assert response.status_code == 200
            assert response.json()["data"]["items"] == []
            assert search.call_args.kwargs["city_id"] == "pune"
    finally:
        app.dependency_overrides.pop(get_db, None)


def test_places_namespace_contains_no_planner_writes():
    schema = app.openapi()
    assert "/api/v1/places/search" in schema["paths"]
    assert "post" not in schema["paths"]["/api/v1/places/"]


import pytest
from test_saved_places import api
from app.modules.place.model import Place
from app.modules.country.model import Country
from app.modules.state.model import State
from app.modules.city.model import City


@pytest.mark.asyncio
async def test_photo_country_totals_and_hidden_geography(api):
    client, _, sessions = api
    async with sessions() as db:
        first = await db.get(Place, "place")
        first.image_url = "https://example.com/photo.jpg"
        db.add(
            Country(
                id="other",
                name="Other",
                iso2="OT",
                iso3="OTH",
                phone_code="2",
                currency_code="OTC",
                currency_name="Other",
                capital="Other",
                continent="Test",
                timezone="UTC",
            )
        )
        await db.commit()
        db.add(
            State(id="other-state", country_id="other", name="Other state", code="OS")
        )
        await db.commit()
        db.add(
            City(
                id="other-city",
                country_id="other",
                state_id="other-state",
                name="Other city",
            )
        )
        await db.commit()
        db.add_all(
            [
                Place(
                    id="blank",
                    city_id="city",
                    name="No photo",
                    slug="no-photo",
                    place_type="museum",
                    image_url="  ",
                ),
                Place(
                    id="invalid",
                    city_id="city",
                    name="Invalid photo",
                    slug="invalid-photo",
                    place_type="museum",
                    image_url="javascript:invalid",
                ),
                Place(
                    id="other-place",
                    city_id="other-city",
                    name="Other photo",
                    slug="other-photo",
                    place_type="attraction",
                    image_url="https://example.com/other.jpg",
                ),
            ]
        )
        await db.commit()
    result = await client.get(
        "/api/v1/places/search?has_photo=true&country_id=country&size=1"
    )
    assert result.status_code == 200, result.text
    data = result.json()["data"]
    assert data["total"] == 1 and data["pages"] == 1
    assert data["items"][0]["city_name"] == "City"
    assert data["items"][0]["country_id"] == "country"
    other = (await client.get("/api/v1/places/search?country_id=other")).json()["data"]
    assert other["total"] == 1 and other["items"][0]["id"] == "other-place"
    async with sessions() as db:
        city = await db.get(City, "city")
        city.is_active = False
        await db.commit()
    assert (await client.get("/api/v1/places/search?country_id=country")).json()[
        "data"
    ]["total"] == 0
    async with sessions() as db:
        city = await db.get(City, "city")
        city.is_active = True
        country = await db.get(Country, "country")
        country.is_active = False
        await db.commit()
    assert (await client.get("/api/v1/places/search?country_id=country")).json()[
        "data"
    ]["items"] == []


@pytest.mark.asyncio
async def test_sights_include_existing_landmarks_without_changing_other_categories(api):
    client, _, sessions = api
    async with sessions() as db:
        db.add(Place(id="sight", city_id="city", name="Historic landmark",
                     slug="historic-sight", place_type="landmark"))
        await db.commit()
    sights = (await client.get("/api/v1/places/search?place_type=attraction")).json()["data"]
    assert any(p["id"] == "sight" for p in sights["items"])
    museums = (await client.get("/api/v1/places/search?place_type=museum")).json()["data"]
    assert all(p["id"] != "sight" for p in museums["items"])
