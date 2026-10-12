from types import SimpleNamespace

import httpx
import pytest
import pytest_asyncio
from sqlalchemy import event
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.main import app
from app.database.base import Base
from app.database.session import get_db
from app.dependencies.current_user import get_current_user
from app.modules.auth.model import User
from app.modules.country.model import Country
from app.modules.state.model import State
from app.modules.city.model import City
from app.modules.place.model import Place
from app.modules.user.model import UserPlaceSave
from app.modules.user.repository import UserRepository


@pytest_asyncio.fixture
async def api():
    engine = create_async_engine('sqlite+aiosqlite:///:memory:')
    @event.listens_for(engine.sync_engine, 'connect')
    def foreign_keys(connection, record):
        connection.execute('PRAGMA foreign_keys=ON')
    tables = [Base.metadata.tables[name] for name in ['users', 'countries', 'states', 'cities', 'categories', 'places', 'user_place_saves', 'user_place_likes', 'user_travel_profiles', 'destinations', 'planners', 'trips', 'itinerary_days', 'itinerary_items', 'ai_routing_settings', 'ai_billing_settings', 'ai_billing_audit_logs', 'ai_usage_records']]
    async with engine.begin() as connection:
        await connection.run_sync(lambda sync: Base.metadata.create_all(sync, tables=tables))
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    async with sessions() as db:
        db.add_all([User(id=id, email=id+'@example.com', full_name=id, password_hash='unused') for id in ['alice', 'bob']])
        db.add(Country(id='country', name='Test country', iso2='TT', iso3='TTT', phone_code='1', currency_code='TST', currency_name='Test', capital='City', continent='Test', timezone='UTC'))
        await db.commit()
        db.add(State(id='state', country_id='country', name='State', code='TS'))
        await db.commit()
        db.add(City(id='city', country_id='country', state_id='state', name='City'))
        await db.commit()
        db.add(Place(id='place', city_id='city', name='Test landmark', slug='test-landmark', place_type='attraction'))
        await db.commit()
    current = SimpleNamespace(id='alice')
    async def database():
        async with sessions() as db:
            yield db
    app.dependency_overrides[get_db] = database
    app.dependency_overrides[get_current_user] = lambda: current
    try:
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app, raise_app_exceptions=False), base_url='http://test') as client:
            yield client, current, sessions
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(get_current_user, None)
        await engine.dispose()


@pytest.mark.asyncio
async def test_save_is_idempotent_persistent_serialized_and_owned(api):
    client, current, sessions = api
    first = await client.post('/api/v1/user/places/place/save')
    assert first.status_code == 200, first.text
    data = first.json()['data']
    assert data['user_id'] == 'alice' and data['place_id'] == 'place'
    assert data['created_at'] and data['id']
    again = await client.post('/api/v1/user/places/place/save')
    assert again.json()['data']['id'] == data['id']
    saved = await client.get('/api/v1/user/saved-places')
    assert saved.status_code == 200
    assert saved.json()['data'][0]['city_id'] == 'city'
    assert saved.json()['data'][0]['name'] == 'Test landmark'
    current.id = 'bob'
    assert (await client.get('/api/v1/user/saved-places')).json()['data'] == []
    await client.delete('/api/v1/user/places/place/save')
    current.id = 'alice'
    assert len((await client.get('/api/v1/user/saved-places')).json()['data']) == 1
    await client.delete('/api/v1/user/places/place/save')
    assert (await client.get('/api/v1/user/saved-places')).json()['data'] == []


@pytest.mark.asyncio
async def test_inactive_and_deleted_places_are_not_saved_or_returned(api):
    client, current, sessions = api
    await client.post('/api/v1/user/places/place/save')
    async with sessions() as db:
        place = await db.get(Place, 'place')
        place.is_active = False
        await db.commit()
    assert (await client.get('/api/v1/user/saved-places')).json()['data'] == []
    assert (await client.post('/api/v1/user/places/place/save')).status_code == 404
    assert (await client.delete('/api/v1/user/places/place/save')).status_code == 200
    assert (await client.post('/api/v1/user/places/missing/save')).status_code == 404
    async with sessions() as db:
        place = await db.get(Place, 'place')
        place.is_active = True
        await db.commit()
    await client.post('/api/v1/user/places/place/save')
    async with sessions() as db:
        place = await db.get(Place, 'place')
        place.is_deleted = True
        await db.commit()
    assert (await client.get('/api/v1/user/saved-places')).json()['data'] == []
    assert (await client.post('/api/v1/user/places/place/save')).status_code == 404


@pytest.mark.asyncio
async def test_unique_conflict_recovers_existing_save(api):
    client, current, sessions = api
    first = (await client.post('/api/v1/user/places/place/save')).json()['data']
    async with sessions() as db:
        duplicate = await UserRepository().add_save(db, UserPlaceSave(user_id='alice', place_id='place'))
        assert duplicate.id == first['id']


@pytest.mark.asyncio
async def test_save_requires_authentication(api):
    client, _, _ = api
    app.dependency_overrides.pop(get_current_user)
    assert (await client.get('/api/v1/user/saved-places')).status_code in (401, 403)


@pytest.mark.asyncio
async def test_travel_preferences_create_update_clear_and_isolate_accounts(api):
    client, current, _ = api
    assert (await client.get('/api/v1/user/profile')).json()['data'] is None
    created = await client.put('/api/v1/user/profile', json={'budget_level': 'Comfort', 'interests': 'Nature, Culture', 'other_preferences': '{"trav_preferences_version":1,"mood":"Relaxed","notes":"Slow pace"}'})
    assert created.status_code == 200, created.text
    identifier = created.json()['data']['id']
    current.id = 'bob'
    assert (await client.get('/api/v1/user/profile')).json()['data'] is None
    await client.put('/api/v1/user/profile', json={'travel_style': 'Solo'})
    current.id = 'alice'
    profile = (await client.get('/api/v1/user/profile')).json()['data']
    assert profile['id'] == identifier and profile['budget_level'] == 'Comfort'
    update = await client.put('/api/v1/user/profile', json={'budget_level': None, 'interests': None, 'other_preferences': None})
    assert update.json()['data']['id'] == identifier
    assert update.json()['data']['budget_level'] is None


@pytest.mark.asyncio
async def test_worldwide_city_trip_crud_validation_and_ownership(api):
    client, current, _ = api
    payload = {'title': 'City escape', 'city_id': 'city', 'start_date': '2026-11-01', 'end_date': '2026-11-03', 'travelers': 2}
    created = await client.post('/api/v1/trips/', json=payload)
    assert created.status_code == 200, created.text
    trip = created.json()['data']
    assert trip['city_id'] == 'city' and trip['destination_id'] is None
    assert (await client.get('/api/v1/trips/')).json()['data']['total'] == 1
    assert (await client.put('/api/v1/trips/'+trip['id'], json={'title': 'Updated escape', 'budget_amount': '15000'})).status_code == 200
    assert (await client.put('/api/v1/trips/'+trip['id'], json={'end_date': '2026-10-01'})).status_code == 422
    assert (await client.put('/api/v1/trips/'+trip['id'], json={'title': None})).status_code == 422
    current.id = 'bob'
    assert (await client.get('/api/v1/trips/'+trip['id'])).status_code == 404
    assert (await client.put('/api/v1/trips/'+trip['id'], json={'title': 'Not mine'})).status_code == 404
    assert (await client.delete('/api/v1/trips/'+trip['id'])).status_code == 404
    assert (await client.get('/api/v1/trips/')).json()['data']['total'] == 0
    current.id = 'alice'
    assert (await client.delete('/api/v1/trips/'+trip['id'])).status_code == 200
    assert (await client.get('/api/v1/trips/')).json()['data']['total'] == 0
    assert (await client.post('/api/v1/trips/', json={**payload, 'city_id': 'missing'})).status_code == 404


@pytest.mark.asyncio
async def test_itinerary_days_activities_reorder_and_ownership(api):
    client, current, _ = api
    trip = (await client.post('/api/v1/trips/', json={'title':'Day plan','city_id':'city','start_date':'2026-11-01','end_date':'2026-11-03'})).json()['data']
    day_path = '/api/v1/itinerary/trips/'+trip['id']+'/days'
    day_payload = {'day_number':1,'date':'2026-11-01','title':'First day'}
    day_response = await client.post(day_path, json=day_payload)
    assert day_response.status_code == 200, day_response.text
    day = day_response.json()['data']
    assert day['items'] == []
    assert (await client.post(day_path, json=day_payload)).status_code == 409
    assert (await client.post(day_path, json={'day_number':2,'date':'2026-12-01'})).status_code == 422
    items_path = '/api/v1/itinerary/days/'+day['id']+'/items'
    first = (await client.post(items_path,json={'title':'Visit landmark','place_id':'place'})).json()['data']
    second = (await client.post(items_path,json={'title':'Quiet afternoon'})).json()['data']
    assert second['sequence'] == 2
    assert (await client.put('/api/v1/itinerary/items/'+first['id'],json={'title':None})).status_code == 422
    assert (await client.put('/api/v1/itinerary/days/'+day['id'],json={'day_number':None})).status_code == 422
    assert (await client.post(items_path,json={'title':'Invalid location','latitude':91,'longitude':1})).status_code == 422
    assert (await client.post(items_path,json={'title':'Invalid times','start_time':'15:00','end_time':'14:00'})).status_code == 422
    order_path = '/api/v1/itinerary/days/'+day['id']+'/order'
    reordered = await client.put(order_path,json={'item_ids':[second['id'],first['id']]})
    assert reordered.status_code == 200, reordered.text
    assert reordered.json()['data']['items'][0]['id'] == second['id']
    assert (await client.put(order_path,json={'item_ids':['missing']})).status_code == 409
    current.id = 'bob'
    assert (await client.get('/api/v1/itinerary/trips/'+trip['id'])).status_code == 404
    assert (await client.delete('/api/v1/itinerary/items/'+first['id'])).status_code == 404
    assert (await client.put(order_path,json={'item_ids':[second['id'],first['id']]})).status_code == 404
    current.id = 'alice'
    assert (await client.delete('/api/v1/itinerary/items/'+first['id'])).status_code == 200
    assert (await client.delete('/api/v1/itinerary/days/'+day['id'])).status_code == 200
    assert (await client.get('/api/v1/itinerary/trips/'+trip['id'])).json()['data']['days'] == []


@pytest.mark.asyncio
async def test_admin_provider_order_is_persistent_audited_and_private(api):
    from app.modules.admin.model import AIBillingAuditLog
    from sqlalchemy import select
    client, current, sessions = api
    current.role = 'user'
    path = '/api/v1/admin/ai-billing/routing'
    assert (await client.get(path)).status_code == 403
    assert (await client.put(path,json={'provider_order':['gemini']})).status_code == 403
    current.role = 'admin'
    updated = await client.put(path,json={'provider_order':['gemini','groq'], 'enabled':False})
    assert updated.status_code == 200, updated.text
    result = (await client.get(path)).json()
    assert result['provider_order'] == ['gemini','groq'] and result['enabled'] is False
    assert 'api_key' not in updated.text.lower()
    assert (await client.put(path,json={'provider_order':['openai','openai']})).status_code == 422
    async with sessions() as db:
        logs = (await db.execute(select(AIBillingAuditLog))).scalars().all()
        assert logs[-1].action == 'routing_update' and logs[-1].admin_id == 'alice'


@pytest.mark.asyncio
async def test_ai_usage_report_counts_reported_tokens_only(api, monkeypatch):
    from app.services.ai import free_runtime
    from app.integrations.llm.base import LLMResponse, LLMUsage
    client, current, sessions = api
    current.role = 'admin'
    monkeypatch.setattr(free_runtime, 'SessionLocal', sessions)
    await free_runtime.record('groq',response=LLMResponse(content='Private plan',provider='groq',model='test',usage=LLMUsage(input_tokens=10,output_tokens=5,total_tokens=15)))
    await free_runtime.record('groq',error='429')
    response = await client.get('/api/v1/admin/ai-billing/usage')
    assert response.status_code == 200, response.text
    assert response.json()['providers'] == [{'provider':'groq','attempts':2,'input_tokens':10,'output_tokens':5,'total_tokens':15}]
    assert 'Private plan' not in response.text
    current.role = 'user'
    assert (await client.get('/api/v1/admin/ai-billing/usage')).status_code == 403
