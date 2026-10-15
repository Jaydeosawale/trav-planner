"""Bounded public-area queries to the app-permitted Private.coffee endpoint.

Only an existing city centre is transmitted, never a user's GPS origin or text.
No account, paid fallback, arbitrary endpoint, photos or inferred opening status.
"""

import math
from app.services.discovery import world

ENDPOINT = "https://overpass.kumi.systems/api/interpreter"
FILTERS = {
    "restaurant": "[amenity=restaurant]",
    "cafe": "[amenity=cafe]",
    "hotel": '[tourism~"^(hotel|hostel|guest_house|motel|camp_site)$"]',
    "station": "[railway=station]",
    "bus_stop": "[highway=bus_stop]",
    "airport": "[aeroway=aerodrome]",
    "parking": "[amenity=parking]",
    "shop": "[shop]",
    "pharmacy": "[amenity=pharmacy]",
    "hospital": '[amenity~"^(hospital|clinic)$"]',
    "worship": "[amenity=place_of_worship]",
    "toilet": "[amenity=toilets]",
    "viewpoint": "[tourism=viewpoint]",
    "charging": "[amenity=charging_station]",
    "attraction": "[tourism=attraction]",
    "museum": "[tourism=museum]",
    "park": "[leisure=park]",
    "heritage": "[historic]",
    "beach": "[natural=beach]",
}


def classify(tags):
    for kind, key, values in [
        ("restaurant", "amenity", {"restaurant", "fast_food", "food_court"}),
        ("cafe", "amenity", {"cafe"}),
        ("pharmacy", "amenity", {"pharmacy"}),
        ("hospital", "amenity", {"hospital", "clinic"}),
        ("worship", "amenity", {"place_of_worship"}),
        ("toilet", "amenity", {"toilets"}),
        ("charging", "amenity", {"charging_station"}),
        ("parking", "amenity", {"parking"}),
        ("station", "railway", {"station", "halt"}),
        ("bus_stop", "highway", {"bus_stop"}),
        ("airport", "aeroway", {"aerodrome"}),
        ("hotel", "tourism", {"hotel", "hostel", "guest_house", "motel", "camp_site"}),
        ("museum", "tourism", {"museum"}),
        ("viewpoint", "tourism", {"viewpoint"}),
        ("park", "leisure", {"park", "garden"}),
        ("beach", "natural", {"beach"}),
    ]:
        if tags.get(key) in values:
            return kind
    if tags.get("historic"):
        return "heritage"
    if tags.get("shop"):
        return "shop"
    return "attraction"


async def fetch(city_id, lat, lon, kind):
    if kind not in FILTERS and kind != "all":
        raise ValueError("Unsupported category")
    if not all(math.isfinite(n) for n in (lat, lon)) or not (
        -90 <= lat <= 90 and -180 <= lon <= 180
    ):
        raise ValueError("Invalid public area")
    from app.services.discovery import geoapify

    if geoapify.enabled() and kind in geoapify.CATEGORIES:
        return await geoapify.fetch(city_id, lat, lon, kind)
    # Fixed categories and validated numbers only; no user text in Overpass QL.
    filters = list(FILTERS.values()) if kind == "all" else [FILTERS[kind]]
    query = (
        "[out:json][timeout:10][maxsize:16777216];("
        + "".join(f"nwr(around:5000,{lat},{lon}){f}[name];" for f in filters)
        + ");out center 80;"
    )
    data = await world.request_json(ENDPOINT, {"data": query}, method="GET")
    if data.get("remark"):
        raise RuntimeError("Open map search timed out. Known places remain available.")
    items = []
    for e in data.get("elements", [])[:80]:
        if (
            e.get("type") not in ("node", "way", "relation")
            or not isinstance(e.get("id"), int)
            or e["id"] <= 0
        ):
            continue
        tags = e.get("tags", {})
        name = tags.get("name:en") or tags.get("name")
        point = e if e["type"] == "node" else e.get("center", {})
        x, y = point.get("lat"), point.get("lon")
        if (
            not name
            or not isinstance(name, str)
            or len(name) > 200
            or not all(isinstance(n, (int, float)) and math.isfinite(n) for n in (x, y))
        ):
            continue
        if (
            not (-90 <= x <= 90 and -180 <= y <= 180)
            or world.distance(lat, lon, x, y) > 5.1
        ):
            continue
        if (
            tags.get("disused") == "yes"
            or tags.get("abandoned") == "yes"
            or tags.get("access") == "private"
        ):
            continue
        external = f"{e['type']}/{e['id']}"
        facts = []
        for key, label in [
            ("cuisine", "Cuisine"),
            ("opening_hours", "Listed hours (unverified)"),
            ("wheelchair", "Wheelchair tag"),
            ("fee", "Fee tag"),
        ]:
            value = tags.get(key)
            if isinstance(value, str) and len(value) <= 200:
                facts.append(f"{label}: {value}")
        items.append(
            {
                "id": world.uid("osm:" + external),
                "city_id": city_id,
                "name": name,
                "slug": "osm-" + external.replace("/", "-"),
                "place_type": classify(tags),
                "description": "; ".join(facts)[:1000],
                "latitude": x,
                "longitude": y,
                "provider": "osm",
                "external_place_id": external,
                "is_active": True,
                "is_featured": False,
                "is_discovery": True,
                "image_url": None,
                "image_credit": None,
                "visiting_notes": "OpenStreetMap contributors · ODbL-1.0. Retrieved "
                + world.now().date().isoformat()
                + ". Listed tags can be outdated; verify hours, access, prices and availability. No live status is inferred.",
            }
        )
    return sorted(
        items, key=lambda p: world.distance(lat, lon, p["latitude"], p["longitude"])
    )[:40]
