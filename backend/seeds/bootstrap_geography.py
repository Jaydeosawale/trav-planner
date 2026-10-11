"""Bounded offline geography import; existing records always win over source data."""
import asyncio
import gzip
import json
import math
from pathlib import Path

from sqlalchemy import insert, select, text
from seeds.bootstrap_catalogue import stable_id
from app.modules.country.model import Country
from app.modules.state.model import State
from app.modules.city.model import City

MANIFEST = Path(__file__).parent / 'data' / 'geonames_major_cities.json.gz'
# Reviewed crosswalk for the seven Wikidata starter cities. Stable identities also
# preserve admin renames and avoid mixing GeoNames FIPS codes with ISO region codes.
STARTER_IDS = dict(zip(['1275339','2988507','1850147','5128581','2147714','3369157','3451190'],
                      ['Q1156','Q90','Q1490','Q60','Q3130','Q5465','Q8678']))


def read_manifest(path=MANIFEST):
    with gzip.open(path, 'rt') as source:
        data = json.load(source)
    if data['license'] != 'CC-BY-4.0' or len(data['cities']) > 40000 or len(data['countries']) > 260:
        raise ValueError('Unreviewed or oversized geography snapshot')
    ids = set()
    codes = {c['iso2'] for c in data['countries']}
    for c in data['cities']:
        if c['id'] in ids or c['country'] not in codes or not c['region'].startswith(c['country'] + '.'):
            raise ValueError('Invalid geography identity')
        ids.add(c['id'])
        lat, lon = c['latitude'], c['longitude']
        if not math.isfinite(lat + lon) or not (-90 <= lat <= 90 and -180 <= lon <= 180):
            raise ValueError('Invalid geography coordinates')
    return data


async def bootstrap(db, data):
    counts = dict(countries=0, states=0, cities=0)
    async with db.begin():
        if db.bind.dialect.name == 'postgresql':
            await db.execute(text('SELECT pg_advisory_xact_lock(20261011, 2)'))
            # Product guard, below the provider's quota; never auto-upgrade storage.
            size = await db.scalar(text('SELECT pg_database_size(current_database())'))
            if size > 700 * 1024 * 1024:
                print('Geography import skipped: database storage guard reached')
                return counts
        countries = {c.iso2: c for c in (await db.scalars(select(Country))).all()}
        for record in data['countries']:
            if record['iso2'] not in countries:
                obj = Country(id=stable_id('country', 'geonames:' + record['iso2']), **record, is_active=True)
                db.add(obj)
                countries[obj.iso2] = obj
                counts['countries'] += 1
        await db.flush()
        states = (await db.scalars(select(State))).all()
        by_id = {s.id: s for s in states}
        by_code = {(s.country_id, s.code): s for s in states}
        by_name = {(s.country_id, s.name.casefold()): s for s in states}
        existing = (await db.scalars(select(City))).all()
        cities_by_id = {c.id: c for c in existing}
        cities_by_name = {(c.state_id, c.name): c for c in existing}
        region_aliases = {}
        for record in data['cities']:
            qid = STARTER_IDS.get(record['id'])
            original = cities_by_id.get(stable_id('city', qid)) if qid else None
            if original:
                region_aliases[record['region']] = by_id[original.state_id]
        pending = []
        for record in data['cities']:
            country = countries[record['country']]
            if country.is_deleted or not country.is_active:
                continue
            key = record['region']
            state_id = stable_id('state', 'geonames:' + key)
            state = (region_aliases.get(key) or by_id.get(state_id) or
                     by_code.get((country.id, 'GN:' + key.split('.', 1)[1])) or
                     by_name.get((country.id, record['region_name'].casefold())))
            if state is None:
                state = State(id=state_id, country_id=country.id, code='GN:' + key.split('.', 1)[1],
                              name=record['region_name'], is_active=True)
                db.add(state)
                by_id[state.id] = state
                by_name[(country.id, state.name.casefold())] = state
                counts['states'] += 1
            region_aliases[key] = state
            if state.is_deleted or not state.is_active:
                continue
            qid = STARTER_IDS.get(record['id'])
            city_id = stable_id('city', qid) if qid else stable_id('city', 'geonames:' + record['id'])
            name_key = (state.id, record['name'])
            if city_id in cities_by_id or name_key in cities_by_name:
                continue
            pending.append(dict(id=city_id, country_id=country.id, state_id=state.id,
                name=record['name'], latitude=record['latitude'], longitude=record['longitude'],
                is_active=True, is_deleted=False))
            cities_by_id[city_id] = True
            cities_by_name[name_key] = True
        await db.flush()
        # Small batches limit memory and parameter counts on free hosting.
        for start in range(0, len(pending), 500):
            await db.execute(insert(City), pending[start:start + 500])
        counts['cities'] = len(pending)
    return counts


async def main():
    from app.database.session import SessionLocal, engine
    try:
        async with SessionLocal() as db:
            print('Geography additions:', await bootstrap(db, read_manifest()))
    finally:
        await engine.dispose()


if __name__ == '__main__':
    asyncio.run(main())
