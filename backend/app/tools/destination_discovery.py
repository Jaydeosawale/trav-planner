"""One bounded source search for an unambiguously chosen public destination."""

from sqlalchemy import select
from app.tools.base import Tool
from app.modules.city.model import City
from app.modules.country.model import Country
from app.modules.state.model import State
from app.services.discovery.world import discover, KINDS


class DestinationDiscoveryTool(Tool):
    @property
    def name(self):
        return "destination_discovery"

    @property
    def description(self):
        return "Find sourced places in a named city. Ask for country when ambiguous; results are not live availability."

    async def execute(
        self, *, db, city_name, kind="local", country_code=None, **kwargs
    ):
        if (
            not isinstance(city_name, str)
            or not 2 <= len(city_name) <= 80
            or kind not in KINDS
        ):
            return {
                "items": [],
                "message": "Choose a valid city and supported category.",
            }
        q = (
            select(City, Country)
            .join(Country, Country.id == City.country_id)
            .join(State, State.id == City.state_id)
            .where(
                City.name.ilike(city_name.strip()),
                City.is_active.is_(True),
                City.is_deleted.is_(False),
                Country.is_active.is_(True),
                Country.is_deleted.is_(False),
                State.is_active.is_(True),
                State.is_deleted.is_(False),
            )
        )
        if country_code:
            q = q.where(Country.iso2 == str(country_code).upper()[:2])
        choices = (await db.execute(q.limit(5))).all()
        if not choices:
            # Resolve only an exact, unique town from the bundled index. No
            # arbitrary text/geocoding service and no disabled-place resurrection.
            existing_query = (
                select(City.id)
                .join(Country, Country.id == City.country_id)
                .where(City.name.ilike(city_name.strip()))
            )
            if country_code:
                existing_query = existing_query.where(
                    Country.iso2 == str(country_code).upper()[:2]
                )
            if await db.scalar(existing_query.limit(1)) is not None:
                return {
                    "items": [],
                    "message": "This destination is unavailable. Choose another destination.",
                }
            from starlette.concurrency import run_in_threadpool
            from app.services.discovery import locations

            try:
                towns = await run_in_threadpool(
                    locations.search,
                    city_name,
                    str(country_code).upper()[:2] if country_code else None,
                )
                exact = [
                    t
                    for t in towns
                    if locations.normalize(t["name"]) == locations.normalize(city_name)
                ]
                if len(exact) == 1:
                    city = await locations.resolve_location(db, exact[0])
                    choices = [(city, await db.get(Country, city.country_id))]
            except Exception:
                return {
                    "items": [],
                    "message": "The town index is temporarily unavailable. Choose this destination in Explore or retry later.",
                }
        if len(choices) != 1:
            return {
                "items": [],
                "destinations": [
                    {"city": c.name, "country": co.name, "country_code": co.iso2}
                    for c, co in choices
                ],
                "message": "Ask the user to choose a country, or choose the destination in Explore. Never guess.",
            }
        city, _ = choices[0]
        result = await discover(db, city.id, kind)
        result["items"] = [
            {
                k: p.get(k)
                for k in [
                    "id",
                    "name",
                    "city_id",
                    "place_type",
                    "latitude",
                    "longitude",
                    "description",
                    "provider",
                    "external_place_id",
                    "visiting_notes",
                ]
            }
            for p in result.get("items", [])[:10]
        ]
        return result
