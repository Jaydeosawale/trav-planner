import asyncio
import copy
import json

import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from seeds.bootstrap_catalogue import bootstrap, read_manifest
from app.modules.country.model import Country
from app.modules.state.model import State
from app.modules.city.model import City
from app.modules.destination.model import Destination
from app.modules.place.model import Place


def test_manifest_has_sourced_locations_across_six_continents():
    entries = read_manifest()
    assert len(entries) == 7
    assert len({e['country']['continent'] for e in entries}) == 6
    assert all(p['source_license'] == 'CC0-1.0' for e in entries for p in e['places'])


def test_invalid_coordinates_fail_before_import(tmp_path):
    entries = copy.deepcopy(read_manifest())
    entries[0]['places'][0]['latitude'] = 91
    path = tmp_path / 'bad.json'
    path.write_text(json.dumps({'destinations': entries}))
    with pytest.raises(ValueError, match='coordinate'):
        read_manifest(path)


def test_restarts_preserve_edits_deleted_places_and_stable_city_ids():
    async def check():
        engine = create_async_engine('sqlite+aiosqlite:///:memory:')
        tables = [Country.__table__, State.__table__, City.__table__, Destination.__table__, Place.__table__]
        async with engine.begin() as conn:
            for table in tables:
                await conn.run_sync(lambda connection, table=table: table.create(connection))
        session = async_sessionmaker(engine, expire_on_commit=False)
        entries = read_manifest()
        async with session() as db:
            additions = await bootstrap(db, entries)
            assert additions == dict(countries=7, states=7, cities=7, destinations=7, places=7)
            city = await db.scalar(select(City).where(City.name == 'Mumbai'))
            city.name = 'Mumbai edited'
            destination = await db.scalar(select(Destination).where(Destination.slug == 'mumbai'))
            destination.slug = 'mumbai-edited'
            destination.description = 'Admin description'
            place = await db.scalar(select(Place).where(Place.slug == 'gateway-of-india'))
            place.is_deleted = True
            await db.commit()
            assert all(value == 0 for value in (await bootstrap(db, entries)).values())
            assert destination.description == 'Admin description'
            assert place.is_deleted
            assert city.name == 'Mumbai edited'
            assert await db.scalar(select(func.count()).select_from(Place)) == 7
        await engine.dispose()
    asyncio.run(check())


def test_inactive_country_does_not_receive_new_children():
    async def check():
        engine = create_async_engine('sqlite+aiosqlite:///:memory:')
        async with engine.begin() as conn:
            for table in [Country.__table__, State.__table__, City.__table__, Destination.__table__, Place.__table__]:
                await conn.run_sync(lambda connection, table=table: table.create(connection))
        session = async_sessionmaker(engine, expire_on_commit=False)
        entry = read_manifest()[0]
        async with session() as db:
            db.add(Country(**entry['country'], is_active=False))
            await db.commit()
            assert all(value == 0 for value in (await bootstrap(db, [entry])).values())
        await engine.dispose()
    asyncio.run(check())
