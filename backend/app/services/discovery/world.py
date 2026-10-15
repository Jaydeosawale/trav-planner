"""Free-only, bounded discovery. Public endpoints never choose provider URLs."""

import asyncio
import html
import json
import math
import re
from datetime import datetime, timedelta, timezone
from uuid import uuid5, NAMESPACE_URL
import httpx
from fastapi import HTTPException
from sqlalchemy import LargeBinary, select, delete, func, text
from sqlalchemy.orm import Mapped, mapped_column
from app.database.base import Base
from app.database.session import SessionLocal
from app.modules.city.model import City
from app.modules.place.model import Place

MAX_CALLS = 200
MAX_CACHE_ROWS = 2500
MAX_CACHE_BYTES = 12 * 1024 * 1024
MAX_DB_BYTES = 200 * 1024 * 1024
KINDS = {
    "local": None,
    "attraction": "Q570116",
    "museum": "Q33506",
    "park": "Q22698",
    "beach": "Q40080",
    "heritage": "Q4989906",
    "restaurant": None,
    "cafe": None,
    "hotel": None,
    "station": None,
    "bus_stop": None,
    "parking": None,
    "shop": None,
    "airport": None,
    "pharmacy": None,
    "hospital": None,
    "worship": None,
    "toilet": None,
    "viewpoint": None,
    "charging": None,
}
_lock = asyncio.Lock()


from app.services.discovery.models import DiscoveryCache, DiscoveryBudget


def now():
    return datetime.now(timezone.utc)


def uid(source):
    return str(uuid5(NAMESPACE_URL, "urn:trav:discovery:" + source))


def future(value):
    return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value


async def settings(db):
    row = await db.get(DiscoveryCache, "settings")
    return json.loads(row.value) if row else {"enabled": True, "daily_calls": MAX_CALLS}


async def stats(db):
    from app.services.discovery import geoapify

    measure = (
        func.octet_length(DiscoveryCache.value)
        if db.bind.dialect.name == "postgresql"
        else func.length(func.cast(DiscoveryCache.value, LargeBinary))
    )
    rows, size = (
        await db.execute(
            select(func.count(), func.coalesce(func.sum(measure), 0)).where(
                DiscoveryCache.kind != "settings"
            )
        )
    ).one()
    database_bytes = None
    if db.bind.dialect.name == "postgresql":
        database_bytes = await db.scalar(
            text("SELECT pg_database_size(current_database())")
        )
    budget = await db.get(DiscoveryBudget, now().date().isoformat())
    return {
        "cache_rows": rows,
        "cache_bytes": size,
        "database_bytes": database_bytes,
        "calls_today": budget.calls if budget else 0,
        "cache_limit_bytes": MAX_CACHE_BYTES,
        "database_stop_bytes": MAX_DB_BYTES,
        "cache_limit_rows": MAX_CACHE_ROWS,
        **await settings(db),
        "cost_policy": "free_only",
        "paid_fallback": False,
        "additional_places_source": (
            "geoapify_free" if geoapify.enabled() else "not_configured"
        ),
        "source_request_result_limit": 20 if geoapify.enabled() else 40,
    }


async def reserve():
    async with SessionLocal() as db:
        if db.bind.dialect.name == "postgresql":
            await db.execute(text("SELECT pg_advisory_xact_lock(20261013, 7)"))
        config = await settings(db)
        if not config["enabled"]:
            raise RuntimeError("Discovery is paused by the administrator.")
        day = now().date().isoformat()
        row = await db.get(DiscoveryBudget, day)
        if row is None:
            row = DiscoveryBudget(day=day, calls=0)
            db.add(row)
        if row.calls >= min(MAX_CALLS, config["daily_calls"]):
            raise RuntimeError("Today’s free discovery limit has been reached.")
        row.calls += 1
        await db.execute(
            delete(DiscoveryBudget).where(
                DiscoveryBudget.day < (now() - timedelta(days=7)).date().isoformat()
            )
        )
        await db.commit()


async def request_json(
    url, params, *, accept=None, method="GET", secret_headers=None, json_body=None
):
    cooldown_key = "cooldown:" + url.split("/")[2]
    async with SessionLocal() as db:
        cooldown = await db.get(DiscoveryCache, cooldown_key)
        if cooldown and future(cooldown.expires_at) > now():
            raise RuntimeError(
                "The free source is cooling down. Known places remain available."
            )
    await reserve()
    headers = {
        "User-Agent": "TravDiscovery/1.0 (+https://github.com/Jaydeosawale/trav-planner)",
        "Accept": accept or "application/json",
    }
    if secret_headers:
        headers.update(secret_headers)
    payload = (
        {"json": json_body}
        if json_body is not None
        else ({"data": params} if method == "POST" else {"params": params})
    )
    async with httpx.AsyncClient(timeout=18, follow_redirects=False) as client:
        async with client.stream(
            method,
            url,
            headers=headers,
            **payload,
        ) as response:
            if response.status_code == 429:
                try:
                    seconds = max(
                        60, min(86400, int(response.headers.get("Retry-After", "300")))
                    )
                except ValueError:
                    try:
                        from email.utils import parsedate_to_datetime

                        seconds = max(
                            60,
                            min(
                                86400,
                                int(
                                    (
                                        parsedate_to_datetime(
                                            response.headers["Retry-After"]
                                        )
                                        - now()
                                    ).total_seconds()
                                ),
                            ),
                        )
                    except Exception:
                        seconds = 300
                async with SessionLocal() as db:
                    await cache_put(
                        db,
                        cooldown_key,
                        "cooldown",
                        {"source": url.split("/")[2]},
                        timedelta(seconds=seconds),
                    )
                    await db.commit()
                raise RuntimeError(
                    "The free source is cooling down. Known places remain available."
                )
            response.raise_for_status()
            raw = bytearray()
            async for chunk in response.aiter_bytes():
                raw.extend(chunk)
                if len(raw) > 2 * 1024 * 1024:
                    raise ValueError("Source response too large.")
            parsed = json.loads(raw)
            if isinstance(parsed, dict) and "error" in parsed:
                raise RuntimeError(
                    "The free source is temporarily busy. Known places remain available."
                )
            return parsed


def distance(a, b, c, d):
    r = math.pi / 180
    v = (
        math.sin((c - a) * r / 2) ** 2
        + math.cos(a * r) * math.cos(c * r) * math.sin((d - b) * r / 2) ** 2
    )
    return 6371 * 2 * math.asin(min(1, math.sqrt(v)))


async def wikidata(city_id, lat, lon, kind):
    # All interpolation inputs are validated numbers or fixed class IDs.
    roots = (
        "wd:" + KINDS[kind]
        if kind != "attraction"
        else "wd:Q570116 wd:Q33506 wd:Q4989906 wd:Q22698 wd:Q40080"
    )
    query = f"""SELECT DISTINCT ?item ?coord WHERE {{
      SERVICE wikibase:around {{ ?item wdt:P625 ?coord .
        bd:serviceParam wikibase:center "Point({lon} {lat})"^^geo:wktLiteral .
        bd:serviceParam wikibase:radius "15" . }}
      VALUES ?root {{ {roots} }}
      ?item wdt:P31/wdt:P279* ?root .
    }} LIMIT 20"""
    data = await request_json(
        "https://query.wikidata.org/sparql", {"query": query, "format": "json"}
    )
    ids = []
    for result in data.get("results", {}).get("bindings", []):
        q = result.get("item", {}).get("value", "").rsplit("/", 1)[-1]
        if re.fullmatch(r"Q[1-9][0-9]*", q) and q not in ids:
            ids.append(q)
    if not ids:
        return []
    entities = (
        await request_json(
            "https://www.wikidata.org/w/api.php",
            {
                "action": "wbgetentities",
                "format": "json",
                "ids": "|".join(ids),
                "props": "labels|descriptions|claims|info|sitelinks",
                "languages": "en",
                "maxlag": 5,
            },
        )
    ).get("entities", {})
    items = []
    for q in ids:
        entity = entities.get(q, {})
        claims = entity.get("claims", {})
        coordinates = [
            c for c in claims.get("P625", []) if c.get("rank") != "deprecated"
        ]
        preferred = [c for c in coordinates if c.get("rank") == "preferred"]
        coordinates = preferred or coordinates
        if not coordinates:
            continue
        point = coordinates[0].get("mainsnak", {}).get("datavalue", {}).get("value", {})
        x, y = point.get("latitude"), point.get("longitude")
        if (
            not isinstance(x, (int, float))
            or not isinstance(y, (int, float))
            or not math.isfinite(x)
            or not math.isfinite(y)
            or not (-90 <= x <= 90 and -180 <= y <= 180)
            or distance(lat, lon, x, y) > 16
        ):
            continue
        if not point.get("globe", "").endswith("/Q2"):
            continue
        name = entity.get("labels", {}).get("en", {}).get("value")
        if not name or len(name) > 200:
            continue
        image = claims.get("P18", [])
        filename = (
            image[0].get("mainsnak", {}).get("datavalue", {}).get("value")
            if image
            else None
        )
        items.append(
            {
                "id": uid("wikidata:" + q),
                "city_id": city_id,
                "name": name,
                "slug": "wd-" + q.lower(),
                "place_type": kind,
                "description": entity.get("descriptions", {})
                .get("en", {})
                .get("value", "")[:1000],
                "latitude": x,
                "longitude": y,
                "provider": "wikidata",
                "external_place_id": q,
                "is_active": True,
                "is_featured": False,
                "is_discovery": True,
                "source_revision": entity.get("lastrevid"),
                "image_filename": filename,
                "wikipedia_title": entity.get("sitelinks", {})
                .get("enwiki", {})
                .get("title"),
                "image_url": None,
                "image_credit": None,
                "visiting_notes": "Source data may be incomplete. Check current access, hours and ticket arrangements before visiting.",
            }
        )
    return items


async def cache_put(db, key, kind, value, ttl):
    encoded = json.dumps(value, ensure_ascii=False)
    if len(encoded.encode()) > 64000:
        raise ValueError("Cache record too large.")
    if kind != "settings" and db.bind.dialect.name == "postgresql":
        await db.execute(text("SELECT pg_advisory_xact_lock(20261013, 8)"))
    row = await db.get(DiscoveryCache, key)
    if kind != "settings":
        measure = (
            func.octet_length(DiscoveryCache.value)
            if db.bind.dialect.name == "postgresql"
            else func.length(func.cast(DiscoveryCache.value, LargeBinary))
        )
        count, size = (
            await db.execute(
                select(func.count(), func.coalesce(func.sum(measure), 0)).where(
                    DiscoveryCache.kind != "settings"
                )
            )
        ).one()
        if (row is None and count >= MAX_CACHE_ROWS) or size - (
            len(row.value.encode()) if row else 0
        ) + len(encoded.encode()) > MAX_CACHE_BYTES:
            raise RuntimeError(
                "Free discovery cache is full. Known places remain available."
            )
    if row:
        row.value = encoded
        row.expires_at = now() + ttl
        row.city_id = value.get("city_id")
    else:
        db.add(
            DiscoveryCache(
                key=key,
                kind=kind,
                value=encoded,
                city_id=value.get("city_id"),
                expires_at=now() + ttl,
            )
        )
    await db.flush()


async def visible(db, items, city_id):
    ids = [i["id"] for i in items]
    rows = (
        (await db.scalars(select(Place).where(Place.id.in_(ids)))).all() if ids else []
    )
    existing = {r.id: r for r in rows}
    output = []
    for item in items:
        record = dict(item)
        place = existing.get(record["id"])
        if place:
            if place.is_deleted or not place.is_active or place.city_id != city_id:
                continue
            for k in [
                "name",
                "description",
                "city_id",
                "image_url",
                "image_credit",
                "visiting_notes",
                "latitude",
                "longitude",
                "place_type",
            ]:
                value = getattr(place, k)
                record[k] = (
                    float(value)
                    if k in ["latitude", "longitude"] and value is not None
                    else value
                )
            record["is_discovery"] = place.is_discovery
        output.append(record)
    return output


async def discover(db, city_id, kind="attraction"):
    if kind not in KINDS:
        raise HTTPException(422, "Unsupported discovery category.")
    city = await db.scalar(
        select(City).where(
            City.id == city_id, City.is_active.is_(True), City.is_deleted.is_(False)
        )
    )
    if city is None:
        raise HTTPException(404, "Destination not found.")
    if city.latitude is None or city.longitude is None:
        return {
            "items": [],
            "status": "no_coordinates",
            "message": "This city needs a verified map location.",
        }
    lat, lon = float(city.latitude), float(city.longitude)
    cached = (
        await db.scalars(
            select(DiscoveryCache)
            .where(
                DiscoveryCache.city_id == city_id,
                DiscoveryCache.kind == "candidate",
                DiscoveryCache.expires_at > now(),
            )
            .limit(200)
        )
    ).all()
    regional = [json.loads(r.value) for r in cached]
    regional = await visible(
        db,
        [
            r
            for r in regional
            if r.get("provider") == "osm" and r.get("place_type") == kind
        ],
        city_id,
    )
    if KINDS[kind] is None and regional:
        return {
            "items": regional,
            "status": "regional",
            "message": "Stored OpenStreetMap listings; details and current availability are unverified.",
        }
    key = "city:" + city_id + ":" + kind
    row = await db.get(DiscoveryCache, key)
    stale = json.loads(row.value) if row else {"items": []}
    stale["items"] = await visible(db, stale.get("items", []), city_id)
    if (
        row
        and future(row.expires_at) > now()
        and not (
            KINDS[kind] is None
            and stale.get("status") == "unavailable"
            and stale.get("source_lookup_version", 0) < 2
        )
    ):
        return {**stale, "status": stale.get("status", "cached")}
    if _lock.locked():
        return {
            **stale,
            "status": "busy",
            "message": "Discovery is busy. Known places remain available.",
        }
    async with _lock:
        await db.execute(
            delete(DiscoveryCache)
            .where(DiscoveryCache.kind != "settings", DiscoveryCache.expires_at < now())
            .execution_options(synchronize_session=False)
        )
        usage = await stats(db)
        if (
            usage["cache_rows"] >= MAX_CACHE_ROWS
            or usage["cache_bytes"] >= MAX_CACHE_BYTES
            or (
                usage["database_bytes"] is not None
                and usage["database_bytes"] >= MAX_DB_BYTES
            )
        ):
            await db.commit()
            return {
                **stale,
                "status": "storage_limit",
                "message": "Free storage limit reached. Known places remain available.",
            }
        if not usage["enabled"]:
            await db.commit()
            return {
                **stale,
                "status": "paused",
                "message": "External discovery is paused.",
            }
        # Release cleanup locks before a source cooldown may be written by another session.
        await db.commit()
        try:
            from app.services.discovery import geoapify

            if KINDS[kind] is None or (
                geoapify.enabled() and kind in geoapify.CATEGORIES
            ):
                from app.services.discovery.open_map import fetch

                items = await fetch(
                    city_id, lat, lon, "all" if kind == "local" else kind
                )
            else:
                items = await wikidata(city_id, lat, lon, kind)
            excluded = set()
            for item in items:
                # Preserve existing admin-controlled or already-saved records.
                existing = await db.scalar(
                    select(Place).where(
                        Place.provider == item["provider"],
                        Place.external_place_id == item["external_place_id"],
                    )
                )
                if existing:
                    if existing.is_deleted or not existing.is_active:
                        excluded.add(item["id"])
                        continue
                    item["id"] = existing.id
                    item["is_discovery"] = existing.is_discovery
                    item["description"] = existing.description
                    item["image_url"] = existing.image_url
                    item["image_credit"] = existing.image_credit
                await cache_put(db, item["id"], "candidate", item, timedelta(days=30))
            items = await visible(
                db, [i for i in items if i["id"] not in excluded], city_id
            )
            result = {
                "items": list({p["id"]: p for p in items + regional}.values()),
                "status": "cached",
                "message": (
                    "Up to 40 mapped listings within 5 km of this city centre. Listed hours and availability are unverified."
                    if KINDS[kind] is None
                    else "Source-backed places near this city; coverage may be incomplete."
                ),
            }
            await cache_put(
                db,
                key,
                "search",
                result,
                (
                    (timedelta(hours=24) if KINDS[kind] is None else timedelta(days=7))
                    if items
                    else timedelta(hours=6)
                ),
            )
        except Exception as exc:
            message = (
                str(exc)
                if isinstance(exc, RuntimeError)
                else "The free source is temporarily unavailable. Try again later."
            )
            result = {
                **stale,
                "items": list(
                    {p["id"]: p for p in stale.get("items", []) + regional}.values()
                ),
                "status": "unavailable",
                "source_lookup_version": 2,
                "source_error": (
                    ("HTTP_" + str(exc.response.status_code))
                    if isinstance(exc, httpx.HTTPStatusError)
                    else type(exc).__name__
                ),
                "message": message,
            }
            try:
                await cache_put(db, key, "search", result, timedelta(minutes=2))
            except RuntimeError:
                await db.rollback()
        await db.commit()
        return result


async def candidate(db, ident):
    row = await db.get(DiscoveryCache, ident)
    if row is None or row.kind != "candidate" or future(row.expires_at) < now():
        raise HTTPException(404, "This result expired. Reopen destination discovery.")
    return row, json.loads(row.value)


async def resolve(db, ident):
    existing = await db.scalar(select(Place).where(Place.id == ident))
    if existing:
        if existing.is_deleted or not existing.is_active:
            raise HTTPException(404, "Place unavailable.")
        return existing
    row, item = await candidate(db, ident)
    usage = await stats(db)
    if usage["database_bytes"] is not None and usage["database_bytes"] >= MAX_DB_BYTES:
        raise HTTPException(409, "Free storage limit reached.")
    if await db.scalar(select(func.count()).select_from(Place)) >= 50000:
        raise HTTPException(409, "Published-place limit reached.")
    fields = {
        k: item.get(k)
        for k in [
            "id",
            "city_id",
            "name",
            "slug",
            "place_type",
            "description",
            "latitude",
            "longitude",
            "provider",
            "external_place_id",
            "image_url",
            "image_credit",
            "visiting_notes",
        ]
    }
    existing = Place(
        **fields, is_active=True, is_featured=False, content_revision="discovery-v1"
    )
    db.add(existing)
    try:
        await db.commit()
    except Exception:
        await db.rollback()
        existing = await db.get(Place, ident)
        if existing is None:
            raise HTTPException(409, "Place changed. Reopen discovery before saving.")
    return existing


async def photo(db, ident):
    existing = await db.get(Place, ident)
    if existing is not None:
        if existing.is_deleted or not existing.is_active:
            raise HTTPException(404, "Place unavailable.")
        if not existing.is_discovery or existing.image_url:
            from app.modules.place.schema import PlaceResponse

            return PlaceResponse.model_validate(existing).model_dump(mode="json")
    row, item = await candidate(db, ident)
    if item.get("image_url") or (
        item.get("photo_checked") == now().date().isoformat()
        and item.get("photo_lookup_version") == 2
    ):
        return item
    filename = item.get("image_filename")
    if _lock.locked():
        return {**item, "photo_checked": False}
    async with _lock:
        try:
            if not filename:
                title = item.get("wikipedia_title")
                qid = item.get("external_place_id", "")
                if (
                    not title
                    and item.get("provider") == "wikidata"
                    and re.fullmatch(r"Q[1-9][0-9]*", qid)
                ):
                    entity = (
                        (
                            await request_json(
                                "https://www.wikidata.org/w/api.php",
                                {
                                    "action": "wbgetentities",
                                    "format": "json",
                                    "ids": qid,
                                    "props": "sitelinks",
                                    "maxlag": 5,
                                },
                            )
                        )
                        .get("entities", {})
                        .get(qid, {})
                    )
                    title = entity.get("sitelinks", {}).get("enwiki", {}).get("title")
                    item["wikipedia_title"] = title
                if isinstance(title, str) and 0 < len(title) <= 250:
                    article = await request_json(
                        "https://en.wikipedia.org/w/api.php",
                        {
                            "action": "query",
                            "format": "json",
                            "titles": title,
                            "prop": "pageimages",
                            "piprop": "name",
                            "pilicense": "free",
                            "maxlag": 5,
                        },
                    )
                    filename = next(
                        iter(article.get("query", {}).get("pages", {}).values()), {}
                    ).get("pageimage")
                    item["image_filename"] = filename
            item["photo_checked"] = now().date().isoformat()
            item["photo_lookup_version"] = 2
            if (
                not isinstance(filename, str)
                or len(filename) > 250
                or "|" in filename
                or not filename.lower().endswith((".jpg", ".jpeg", ".png"))
            ):
                await cache_put(db, ident, "candidate", item, timedelta(days=30))
                await db.commit()
                return item
            data = await request_json(
                "https://commons.wikimedia.org/w/api.php",
                {
                    "action": "query",
                    "format": "json",
                    "titles": "File:" + filename,
                    "prop": "imageinfo",
                    "iiprop": "url|extmetadata",
                    "iiurlwidth": 640,
                    "maxlag": 5,
                },
            )
            info = next(iter(data.get("query", {}).get("pages", {}).values())).get(
                "imageinfo", [{}]
            )[0]
            meta = info.get("extmetadata", {})
            plain = lambda k: html.unescape(
                re.sub("<[^>]+>", "", meta.get(k, {}).get("value", ""))
            ).strip()
            licence = plain("LicenseShortName")
            author = plain("Artist")
            licence_url = plain("LicenseUrl").replace("http://", "https://", 1)
            url = info.get("thumburl")
            if (
                licence
                in [
                    "CC BY-SA 4.0",
                    "CC BY-SA 3.0",
                    "CC BY-SA 3.0 de",
                    "CC BY-SA 2.5",
                    "CC BY-SA 2.0",
                    "CC BY 4.0",
                    "CC BY 3.0",
                    "CC BY 2.5",
                    "CC BY 2.0",
                    "CC0",
                    "Public domain",
                ]
                and author
                and len(author) < 2000
                and (
                    licence_url.startswith("https://creativecommons.org/")
                    or licence in ["CC0", "Public domain"]
                )
                and isinstance(url, str)
                and len(url) <= 500
                and (
                    url.startswith("https://upload.wikimedia.org/")
                    or url.startswith("https://thumb.wikimedia.org/")
                )
            ):
                item["image_url"] = url
                item["image_credit"] = json.dumps(
                    {
                        "author": author,
                        "license": licence,
                        "license_url": licence_url
                        or "https://creativecommons.org/publicdomain/mark/1.0/",
                        "source_url": info["descriptionurl"],
                        "attribution": plain("Attribution"),
                        "changes": "Wikimedia thumbnail; resized and cropped for display",
                    }
                )
        except Exception:
            # Temporary quota/cooldown errors must not hide a photo for a whole day.
            item.pop("photo_checked", None)
        if existing is not None and existing.is_discovery and item.get("image_url"):
            existing.image_url = item["image_url"]
            existing.image_credit = item["image_credit"]
        await cache_put(db, ident, "candidate", item, timedelta(days=30))
        await db.commit()
    return item
