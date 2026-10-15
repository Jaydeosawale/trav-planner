"""Optional dedicated Geoapify Free project. No key in URLs, billing or pagination.

One bounded request uses one credit (20 results). All calls share Trav's 200/day
source budget. No retry/account rotation on quota exhaustion. Public city centres
only; not precise user positions, prompts, account identifiers or trip history.
"""

import math
from app.core.settings import settings
from app.services.discovery import world

ENDPOINT = "https://api.geoapify.com/v2/places"
CATEGORIES = {
    "restaurant": ["catering.restaurant"],
    "cafe": ["catering.cafe"],
    "hotel": ["accommodation"],
    "station": ["public_transport.train"],
    "bus_stop": ["public_transport.bus"],
    "airport": ["airport"],
    "parking": ["parking"],
    "shop": ["commercial"],
    "pharmacy": ["healthcare.pharmacy"],
    "hospital": ["healthcare.hospital", "healthcare.clinic_or_praxis"],
    "worship": ["religion.place_of_worship"],
    "toilet": ["amenity.toilet"],
    "viewpoint": ["tourism.attraction.viewpoint"],
    "attraction": ["tourism.attraction", "tourism.sights"],
    "museum": ["entertainment.museum"],
    "park": ["leisure.park"],
    "heritage": ["heritage", "tourism.sights"],
    "beach": ["beach"],
}
CATEGORIES["all"] = list(
    dict.fromkeys(c for values in CATEGORIES.values() for c in values)
)


def enabled():
    return bool(settings.GEOAPIFY_API_KEY and settings.GEOAPIFY_FREE_PLAN_CONFIRMED)


def classify(categories):
    # Specific classes precede generic tourism/accommodation/commercial classes.
    order = [
        "viewpoint",
        "museum",
        "pharmacy",
        "hospital",
        "cafe",
        "restaurant",
        "station",
        "bus_stop",
        "airport",
        "parking",
        "worship",
        "toilet",
        "park",
        "beach",
        "heritage",
        "hotel",
        "shop",
        "attraction",
    ]
    for kind in order:
        if any(
            c == prefix or c.startswith(prefix + ".")
            for c in categories
            for prefix in CATEGORIES[kind]
        ):
            return kind
    return None


async def fetch(city_id, lat, lon, kind):
    if not enabled():
        raise RuntimeError("The additional free places source is not configured.")
    if (
        kind not in CATEGORIES
        or not all(isinstance(n, (int, float)) and math.isfinite(n) for n in (lat, lon))
        or not (-90 <= lat <= 90 and -180 <= lon <= 180)
    ):
        raise ValueError("Invalid public area or category")
    data = await world.request_json(
        ENDPOINT,
        {},
        method="POST",
        secret_headers={"x-api-key": settings.GEOAPIFY_API_KEY},
        json_body={
            "categories": CATEGORIES[kind],
            "filter": {"type": "circle", "lon": lon, "lat": lat, "radius": 5000},
            "bias": {"type": "proximity", "lon": lon, "lat": lat},
            "limit": 20,
            "lang": "en",
        },
    )
    if not isinstance(data, dict) or not isinstance(data.get("features"), list):
        raise ValueError("Invalid places response")
    items = {}
    for feature in data["features"][:20]:
        if not isinstance(feature, dict):
            continue
        p = feature.get("properties")
        if not isinstance(p, dict):
            continue
        name, source_id = p.get("name"), p.get("place_id")
        x, y = p.get("lat"), p.get("lon")
        categories = p.get("categories", [])
        if (
            not isinstance(name, str)
            or not name.strip()
            or len(name) > 200
            or not isinstance(source_id, str)
            or not source_id
            or len(source_id) > 4096
            or not all(
                isinstance(n, (int, float))
                and not isinstance(n, bool)
                and math.isfinite(n)
                for n in (x, y)
            )
            or not (-90 <= x <= 90 and -180 <= y <= 180)
            or world.distance(lat, lon, x, y) > 5.1
            or not isinstance(categories, list)
        ):
            continue
        categories = [c for c in categories if isinstance(c, str)]
        place_type = classify(categories) if kind == "all" else kind
        if not place_type or not any(
            c == prefix or c.startswith(prefix + ".")
            for c in categories
            for prefix in CATEGORIES[kind]
        ):
            continue
        # Preserve OSM identity when exposed, avoiding duplicates across sources.
        datasource = p.get("datasource") or {}
        raw = datasource.get("raw") or {} if isinstance(datasource, dict) else {}
        raw = raw if isinstance(raw, dict) else {}
        osm_type, osm_id = raw.get("osm_type"), str(raw.get("osm_id", ""))
        if (
            osm_type in ("node", "way", "relation")
            and osm_id.isdigit()
            and int(osm_id) > 0
        ):
            provider, external = "osm", osm_type + "/" + osm_id
        else:
            provider, external = "geoapify", world.uid("geoapify:" + source_id)
        ident = world.uid(provider + ":" + external)
        address = p.get("formatted")
        items[ident] = {
            "id": ident,
            "city_id": city_id,
            "name": name.strip(),
            "slug": provider + "-" + ident,
            "place_type": place_type,
            "description": address[:1000] if isinstance(address, str) else "",
            "latitude": x,
            "longitude": y,
            "provider": provider,
            "external_place_id": external,
            "is_active": True,
            "is_featured": False,
            "is_discovery": True,
            "image_url": None,
            "image_credit": None,
            "visiting_notes": "Powered by Geoapify (https://www.geoapify.com/) · "
            "OpenStreetMap contributors · ODbL-1.0. Retrieved "
            + world.now().date().isoformat()
            + ". Coverage may be incomplete; verify access, hours, prices and availability. No live status is inferred.",
        }
    return sorted(
        items.values(),
        key=lambda p: world.distance(lat, lon, p["latitude"], p["longitude"]),
    )
