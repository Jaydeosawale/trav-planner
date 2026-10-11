import asyncio
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from seeds.bootstrap_catalogue import bootstrap as starter, read_manifest as starter_manifest
from seeds.bootstrap_geography import bootstrap, read_manifest
from app.modules.country.model import Country
from app.modules.state.model import State
from app.modules.city.model import City
from app.modules.destination.model import Destination
from app.modules.place.model import Place


def test_snapshot_is_bounded_and_worldwide():
    data = read_manifest()
    assert len(data['countries']) == 250
    assert 30000 < len(data['cities']) <= 40000
    assert len({c['continent'] for c in data['countries']}) == 7
    assert all(len(c['phone_code']) <= 10 for c in data['countries'])


def test_full_import_preserves_starter_and_admin_edits_on_restart():
    async def run():
        engine = create_async_engine('sqlite+aiosqlite:///:memory:')
        async with engine.begin() as conn:
            for table in [Country.__table__, State.__table__, City.__table__, Destination.__table__, Place.__table__]:
                await conn.run_sync(lambda connection, table=table: table.create(connection))
        sessions = async_sessionmaker(engine, expire_on_commit=False)
        async with sessions() as db:
            await starter(db, starter_manifest())
            mumbai = await db.scalar(select(City).where(City.name == 'Mumbai'))
            mumbai.name = 'Mumbai admin edit'
            await db.commit()
            result = await bootstrap(db, read_manifest())
            assert result['countries'] == 243
            assert result['cities'] > 30000
            count = await db.scalar(select(func.count()).select_from(City))
            await db.commit()
            assert await bootstrap(db, read_manifest()) == dict(countries=0, states=0, cities=0)
            assert mumbai.name == 'Mumbai admin edit'
            assert await db.scalar(select(func.count()).select_from(City)) == count
            mumbai.is_deleted = True
            await db.commit()
            assert (await bootstrap(db, read_manifest()))['cities'] == 0
        await engine.dispose()
    asyncio.run(run())


def test_anonymous_users_cannot_modify_city_catalogue():
    from fastapi.testclient import TestClient
    from app.main import app
    client = TestClient(app)
    for method, path in [('post', '/api/v1/cities/'), ('put', '/api/v1/cities/example'), ('delete', '/api/v1/cities/example')]:
        response = getattr(client, method)(path)
        assert response.status_code == 401


def test_public_city_search_includes_coordinates_for_maps():
    from types import SimpleNamespace
    from unittest.mock import AsyncMock, patch
    from fastapi.testclient import TestClient
    from app.main import app
    from app.database.session import get_db
    async def fake_db():
        yield object()
    app.dependency_overrides[get_db] = fake_db
    try:
        with patch('app.modules.city.router.service.search', new_callable=AsyncMock) as search:
            search.return_value = ([SimpleNamespace(id='city', country_id='country', state_id='state',
                name='Barcelona', is_active=True, latitude=41.38879, longitude=2.15899)], 1)
            response = TestClient(app).get('/api/v1/cities/search?search=Barcelona')
            assert response.status_code == 200
            city = response.json()['data']['items'][0]
            assert float(city['latitude']) == 41.38879
            assert float(city['longitude']) == 2.15899
    finally:
        app.dependency_overrides.pop(get_db, None)
