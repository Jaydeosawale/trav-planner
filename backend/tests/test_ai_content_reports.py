import json
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
import httpx
import pytest
import pytest_asyncio
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from app.main import app
from app.database.base import Base
from app.database.session import get_db
from app.dependencies.current_user import get_current_user
from app.services.ai.conversations import PlannerConversation
from app.services.ai.itinerary_models import ItineraryDraft
from app.services.ai.content_reports import AIContentReport

@pytest_asyncio.fixture
async def api():
    engine = create_async_engine('sqlite+aiosqlite:///:memory:')
    async with engine.begin() as conn:
        await conn.run_sync(lambda c: Base.metadata.create_all(c, tables=[PlannerConversation.__table__, ItineraryDraft.__table__, AIContentReport.__table__]))
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    async with sessions() as db:
        db.add(PlannerConversation(id='chat1', user_id='alice', title='Plan', brief_json='{}', turns_json=json.dumps([{'role':'user','content':'private prompt'}, {'role':'assistant','content':'generated answer'}]), version=0))
        db.add(ItineraryDraft(id='draft1', user_id='alice', city_id='city', content_json='{"plan":"generated itinerary"}', expires_at=datetime.now(timezone.utc)+timedelta(days=1)))
        await db.commit()
    current = SimpleNamespace(id='alice', role='user')
    async def database():
        async with sessions() as db: yield db
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
async def test_reports_persist_only_owned_generated_content_and_require_admin(api):
    client, current, sessions = api
    body = {'source_kind':'chat','reference_id':'chat1','reason':'unsafe','details':'Concern'}
    response = await client.post('/api/v1/ai/content-reports', json=body)
    assert response.status_code == 201, response.text
    ident = response.json()['id']
    async with sessions() as db:
        row = await db.get(AIContentReport, ident)
        assert row.content_excerpt == 'generated answer'
        assert row.status == 'pending' and row.user_id == 'alice'
    assert (await client.get('/api/v1/ai/content-reports')).status_code == 403
    assert (await client.patch('/api/v1/ai/content-reports/'+ident, json={'status':'actioned'})).status_code == 403
    current.id = 'bob'
    assert (await client.post('/api/v1/ai/content-reports', json=body)).status_code == 404
    current.role = 'admin'
    assert len((await client.get('/api/v1/ai/content-reports')).json()) == 1
    assert (await client.patch('/api/v1/ai/content-reports/'+ident, json={'status':'actioned'})).json()['status'] == 'actioned'

@pytest.mark.asyncio
async def test_itinerary_validation_rate_limit_and_auth(api):
    client, current, sessions = api
    body = {'source_kind':'itinerary','reference_id':'draft1','reason':'misleading'}
    assert (await client.post('/api/v1/ai/content-reports', json={**body,'details':'x'*1001})).status_code == 422
    current.id = 'bob'
    assert (await client.post('/api/v1/ai/content-reports', json=body)).status_code == 404
    current.id = 'alice'
    for _ in range(20):
        response = await client.post('/api/v1/ai/content-reports', json=body)
        assert response.status_code == 201, response.text
    assert (await client.post('/api/v1/ai/content-reports', json=body)).status_code == 429
    app.dependency_overrides.pop(get_current_user)
    assert (await client.post('/api/v1/ai/content-reports', json=body)).status_code in (401,403)
