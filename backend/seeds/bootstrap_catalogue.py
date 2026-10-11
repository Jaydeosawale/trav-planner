"""Small sourced catalogue, applied once per record without overwriting admin work.

No provider calls or keys are used at deployment/runtime. The checked-in manifest
is reviewed separately; imports run transactionally against the configured DB.
"""
from __future__ import annotations

import asyncio
import json
import math
import re
from pathlib import Path
from uuid import NAMESPACE_URL, uuid5

from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

import app.database.models  # noqa: F401 -- register relationships
from app.modules.country.model import Country
from app.modules.state.model import State
from app.modules.city.model import City
from app.modules.destination.model import Destination
from app.modules.place.model import Place

MANIFEST = Path(__file__).parent / 'data' / 'worldwide_starter.json'


def stable_id(kind: str, key: str) -> str:
    return str(uuid5(NAMESPACE_URL, f'urn:trav:catalogue:{kind}:{key}'))


def read_manifest(path: Path = MANIFEST) -> list[dict]:
    entries = json.loads(path.read_text())['destinations']
    slugs = set()
    for entry in entries:
        for record in [entry['city'], *entry['places']]:
            lat, lon = float(record['latitude']), float(record['longitude'])
            if not math.isfinite(lat) or not math.isfinite(lon) or not (-90 <= lat <= 90 and -180 <= lon <= 180):
                raise ValueError('Invalid catalogue coordinate')
            if not re.fullmatch(r'Q[1-9][0-9]*', record['wikidata_id']) or not record['source_revision']:
                raise ValueError('Catalogue source required')
            if record.get('source_license') != 'CC0-1.0':
                raise ValueError('Reviewed catalogue licence required')
        for slug in [entry['slug'], *(p['slug'] for p in entry['places'])]:
            if slug in slugs:
                raise ValueError('Duplicate catalogue slug')
            slugs.add(slug)
    return entries


async def bootstrap(db: AsyncSession, entries: list[dict]) -> dict[str, int]:
    counts = dict(countries=0, states=0, cities=0, destinations=0, places=0)
    async with db.begin():
        if db.bind.dialect.name == 'postgresql':
            # Serialize concurrent releases of this importer.
            await db.execute(text('SELECT pg_advisory_xact_lock(20261011, 2)'))
        for entry in entries:
            country_data = entry['country']
            country = await db.scalar(select(Country).where(Country.iso2 == country_data['iso2']))
            if country is None:
                country = Country(**country_data, is_active=True)
                db.add(country)
                await db.flush()
                counts['countries'] += 1
            if country.is_deleted or not country.is_active:
                continue
            state_data = entry['state']
            state = await db.scalar(select(State).where(State.country_id == country.id, State.code == state_data['code']))
            if state is None:
                state = State(country_id=country.id, **state_data, is_active=True)
                db.add(state)
                await db.flush()
                counts['states'] += 1
            if state.is_deleted or not state.is_active:
                continue
            city_data = entry['city']
            city_id = stable_id('city', city_data['wikidata_id'])
            city = await db.scalar(select(City).where((City.id == city_id) |
                ((City.state_id == state.id) & (City.name == city_data['name']))))
            if city is None:
                city = City(id=city_id, country_id=country.id, state_id=state.id,
                            name=city_data['name'], latitude=city_data['latitude'],
                            longitude=city_data['longitude'], is_active=True)
                db.add(city)
                await db.flush()
                counts['cities'] += 1
            if city.is_deleted or not city.is_active:
                continue
            destination_id = stable_id('destination', city_data['wikidata_id'])
            destination = await db.scalar(select(Destination).where(
                (Destination.id == destination_id) | (Destination.slug == entry['slug'])))
            if destination is None:
                # Renamed catalogue destinations must not be duplicated on restart.
                destination = await db.scalar(select(Destination).where(Destination.city_id == city.id).limit(1))
            if destination is None:
                destination = Destination(id=destination_id, city_id=city.id, name=city_data['name'],
                    slug=entry['slug'], short_description=entry['description'],
                    description=entry['description'], latitude=city_data['latitude'],
                    longitude=city_data['longitude'], is_active=True, is_featured=True)
                db.add(destination)
                await db.flush()
                counts['destinations'] += 1
            if destination.is_deleted or not destination.is_active:
                continue
            for item in entry['places']:
                place_id = stable_id('place', item['wikidata_id'])
                place = await db.scalar(select(Place).where(
                    (Place.id == place_id) | (Place.slug == item['slug']) |
                    ((Place.provider == 'wikidata') & (Place.external_place_id == item['wikidata_id']))))
                if place is not None:
                    continue
                db.add(Place(id=place_id, city_id=city.id, name=item['name'], slug=item['slug'],
                    place_type=item['type'], short_description=item['description'],
                    description=item['description'], latitude=item['latitude'], longitude=item['longitude'],
                    provider='wikidata', external_place_id=item['wikidata_id'],
                    is_active=True, is_featured=True))
                await db.flush()
                counts['places'] += 1
    return counts


async def main():
    entries = read_manifest()
    from app.database.session import SessionLocal, engine
    try:
        async with SessionLocal() as db:
            print('Catalogue additions:', await bootstrap(db, entries))
    finally:
        await engine.dispose()


if __name__ == '__main__':
    asyncio.run(main())
