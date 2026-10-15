import pytest
from app.services.discovery import geoapify, open_map, world


@pytest.mark.asyncio
async def test_free_gate_and_city_only_secret_header(monkeypatch):
    monkeypatch.setattr(
        geoapify.settings, "GEOAPIFY_API_KEY", "test-only-not-a-real-key"
    )
    monkeypatch.setattr(geoapify.settings, "GEOAPIFY_FREE_PLAN_CONFIRMED", False)
    with pytest.raises(RuntimeError):
        await geoapify.fetch("city", 18.52, 73.85, "cafe")
    calls = []

    async def source(url, params, **kwargs):
        calls.append((url, params, kwargs))

        def feature(name, lat=18.52, category="catering.cafe", raw=None):
            return {
                "properties": {
                    "name": name,
                    "lat": lat,
                    "lon": 73.85,
                    "place_id": name,
                    "categories": [category],
                    "datasource": {"raw": raw or {}},
                }
            }

        return {
            "features": [
                feature("Small café", raw={"osm_type": "node", "osm_id": 42}),
                feature("Small café", raw={"osm_type": "node", "osm_id": 42}),
                feature("Other café"),
                feature("Wrong area", lat=0),
                feature("Wrong category", category="commercial"),
                feature("NaN", lat=float("nan")),
                feature("Broken raw", raw="invalid"),
            ]
        }

    monkeypatch.setattr(world, "request_json", source)
    monkeypatch.setattr(geoapify.settings, "GEOAPIFY_FREE_PLAN_CONFIRMED", True)
    items = await open_map.fetch("city", 18.52, 73.85, "cafe")
    assert len(items) == 3
    assert items[0]["id"] == world.uid("osm:node/42")
    assert all(
        p["image_url"] is None and "Powered by Geoapify" in p["visiting_notes"]
        for p in items
    )
    url, params, request = calls[0]
    assert "test-only" not in url and params == {}
    assert request["secret_headers"] == {"x-api-key": "test-only-not-a-real-key"}
    assert request["json_body"]["limit"] == 20
    assert request["json_body"]["filter"] == {
        "type": "circle",
        "lat": 18.52,
        "lon": 73.85,
        "radius": 5000,
    }
    for lat, lon, kind in [
        (float("nan"), 0, "cafe"),
        (91, 0, "cafe"),
        (0, 0, "unknown"),
    ]:
        with pytest.raises(ValueError):
            await geoapify.fetch("city", lat, lon, kind)
    assert len(calls) == 1


@pytest.mark.asyncio
async def test_quota_error_never_rotates_to_other_source(monkeypatch):
    monkeypatch.setattr(geoapify.settings, "GEOAPIFY_API_KEY", "test-only")
    monkeypatch.setattr(geoapify.settings, "GEOAPIFY_FREE_PLAN_CONFIRMED", True)
    calls = []

    async def source(url, params, **kwargs):
        calls.append(url)
        raise RuntimeError("Free source cooling down")

    monkeypatch.setattr(world, "request_json", source)
    with pytest.raises(RuntimeError, match="cooling down"):
        await open_map.fetch("city", 18.52, 73.85, "cafe")
    assert calls == [geoapify.ENDPOINT]


def test_specific_classification():
    assert (
        geoapify.classify(
            ["tourism", "tourism.attraction", "tourism.attraction.viewpoint"]
        )
        == "viewpoint"
    )
    assert geoapify.classify(["healthcare", "healthcare.pharmacy"]) == "pharmacy"
    assert geoapify.classify(["unrecognized"]) is None
