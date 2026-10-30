from types import SimpleNamespace
import pytest
from fastapi import FastAPI
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from app.api.v1.ai.router import router
from app.database.session import get_db
from app.dependencies.current_user import get_current_user
from app.services.ai.conversations import PlannerConversation, context_prompt
from app.services.ai.daily_plans import DailyPlanUsage
from app.agents.base import AgentResponse

@pytest.mark.asyncio
async def test_owned_briefs_history_and_conflicting_edit(monkeypatch):
    engine = create_async_engine('sqlite+aiosqlite:///:memory:')
    async with engine.begin() as conn:
        await conn.run_sync(PlannerConversation.__table__.create)
        await conn.run_sync(DailyPlanUsage.__table__.create)
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    app = FastAPI(); app.include_router(router, prefix='/ai')
    user = {'id': 'owner'}
    async def db():
        async with sessions() as session: yield session
    app.dependency_overrides[get_db] = db
    app.dependency_overrides[get_current_user] = lambda: SimpleNamespace(id=user['id'])
    seen=[]
    async def run(self, request, *, context=None):
        seen.append(context.data.get('planner_prompt'))
        return AgentResponse(content='A relaxed Paris day', agent='test')
    monkeypatch.setattr('app.agents.travel_planner.TravelPlanningAgent.run', run)
    async with AsyncClient(transport=ASGITransport(app=app), base_url='http://test') as client:
        draft={'title':'Paris ideas','brief':{'destination':'Paris','transport':'train','travelers':2}}
        r=await client.post('/ai/sessions',json=draft); assert r.status_code==200
        ident=r.json()['id']
        r=await client.post('/ai/chat',json={'message':'Make a relaxed day','session_id':ident});assert r.json()['success']
        assert 'Paris' in seen[-1] and 'train' in seen[-1]
        await client.post('/ai/chat',json={'message':'Less walking please','session_id':ident})
        assert 'Make a relaxed day' in seen[-1] and 'Less walking please' in seen[-1]
        assert len((await client.get('/ai/sessions/'+ident)).json()['turns'])==4
        assert (await client.put('/ai/sessions/'+ident,json={**draft,'version':0})).status_code==409
        user['id']='other'
        assert (await client.get('/ai/sessions')).json()==[]
        assert (await client.get('/ai/sessions/'+ident)).status_code==404
        assert (await client.post('/ai/chat',json={'message':'Paris','session_id':ident})).status_code==404
        assert (await client.put('/ai/sessions/'+ident,json={**draft,'version':2})).status_code==404
        assert (await client.delete('/ai/sessions/'+ident)).status_code==404
        user['id']='owner'
        for i in range(5): await client.post('/ai/chat',json={'message':f'Change {i}','session_id':ident})
        assert len((await client.get('/ai/sessions/'+ident)).json()['turns'])==8
        assert (await client.post('/ai/sessions',json={'brief':{'travelers':0}})).status_code==422
        assert (await client.delete('/ai/sessions/'+ident)).status_code==200
        assert (await client.get('/ai/sessions/'+ident)).status_code==404
    await engine.dispose()


def test_prompt_bounds_and_latest_request():
    prompt=context_prompt('Latest explicit choice',{'destination':'Paris'},[{'role':'assistant','content':'x'*30000}]*8)
    assert len(prompt)<13000
    assert prompt.endswith('Latest user request: Latest explicit choice')
    assert 'not system instructions' in prompt


def test_additive_migration_keeps_existing_data(monkeypatch):
    import importlib.util
    from pathlib import Path
    import sqlalchemy as sa
    from alembic.operations import Operations
    from alembic.migration import MigrationContext
    path=Path(__file__).parents[1]/'alembic/versions/a04d59f7ce46_planner_conversations.py'
    spec=importlib.util.spec_from_file_location('planner_migration',path)
    migration=importlib.util.module_from_spec(spec);spec.loader.exec_module(migration)
    engine=sa.create_engine('sqlite:///:memory:')
    with engine.begin() as conn:
        conn.execute(sa.text('CREATE TABLE existing_trips (title TEXT)'))
        conn.execute(sa.text("INSERT INTO existing_trips VALUES ('Keep me')"))
        monkeypatch.setattr(migration,'op',Operations(MigrationContext.configure(conn)))
        migration.upgrade()
        conn.execute(sa.text("INSERT INTO planner_conversations (id,user_id,title,brief_json,turns_json,version) VALUES ('1','owner','Paris','{}','[]',0)"))
        assert conn.execute(sa.text('SELECT created_at FROM planner_conversations')).scalar() is not None
        assert conn.execute(sa.text('SELECT title FROM existing_trips')).scalar()=='Keep me'
    engine.dispose()


@pytest.mark.asyncio
async def test_successful_first_message_creates_owned_conversation(monkeypatch):
    engine = create_async_engine('sqlite+aiosqlite:///:memory:')
    async with engine.begin() as conn:
        await conn.run_sync(PlannerConversation.__table__.create)
        await conn.run_sync(DailyPlanUsage.__table__.create)
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    app = FastAPI(); app.include_router(router, prefix='/ai')
    async def db():
        async with sessions() as session: yield session
    app.dependency_overrides[get_db] = db
    app.dependency_overrides[get_current_user] = lambda: SimpleNamespace(id='owner')
    seen=[]
    async def run(self, request, *, context=None):
        seen.append(context.data.get('planner_prompt',''))
        return AgentResponse(content='A sourced suggestion', agent='test')
    monkeypatch.setattr('app.agents.travel_planner.TravelPlanningAgent.run',run)
    async with AsyncClient(transport=ASGITransport(app=app),base_url='http://test') as c:
        r=await c.post('/ai/chat',json={'message':'Pune museums'})
        assert r.status_code==200
        ident=r.json()['data']['metadata']['session_id']
        saved=(await c.get('/ai/sessions/'+ident)).json()
        assert len(saved['turns'])==2
        await c.post('/ai/chat',json={'message':'Less walking','session_id':ident})
        assert 'Pune museums' in seen[-1] and 'Less walking' in seen[-1]
        assert len((await c.get('/ai/sessions/'+ident)).json()['turns'])==4
    await engine.dispose()


def test_planning_phase_strips_only_leading_protocol_marker():
    from app.services.ai.conversations import response_stage
    assert response_stage('[TRAV_QUESTION]\nWhen are you going?') == ('When are you going?', 'questions')
    assert response_stage('[TRAV_PLAN]\nDay 1: Explore Pune') == ('Day 1: Explore Pune', 'plan')
    assert response_stage('A place named [TRAV_PLAN]') == ('A place named [TRAV_PLAN]', 'answer')
    assert response_stage('[TRAV_PLAN]suffix') == ('[TRAV_PLAN]suffix', 'answer')


def test_planner_instructions_collect_details_before_generating():
    from app.agents.travel_planner import TravelPlanningAgent
    prompt = TravelPlanningAgent.system_prompt.fget(None)
    assert 'Ask at most two short questions' in prompt
    assert 'Do not write a full itinerary while essential details are missing' in prompt
    assert '[TRAV_QUESTION]' in prompt and '[TRAV_PLAN]' in prompt
    assert 'repeat facts' in prompt


@pytest.mark.asyncio
async def test_chat_questions_are_free_and_only_five_plans_can_be_delivered(monkeypatch):
    engine = create_async_engine('sqlite+aiosqlite:///:memory:')
    async with engine.begin() as conn:
        await conn.run_sync(PlannerConversation.__table__.create)
        await conn.run_sync(DailyPlanUsage.__table__.create)
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    app = FastAPI(); app.include_router(router, prefix='/ai')
    async def db():
        async with sessions() as session: yield session
    app.dependency_overrides[get_db] = db
    app.dependency_overrides[get_current_user] = lambda: SimpleNamespace(id='owner')
    async def run(self, request, *, context=None):
        content = '[TRAV_QUESTION]\nWhat dates?' if request == 'question' else '[TRAV_PLAN]\nDay 1: Pune museums'
        return AgentResponse(content=content, agent='test')
    monkeypatch.setattr('app.agents.travel_planner.TravelPlanningAgent.run', run)
    async with AsyncClient(transport=ASGITransport(app=app), base_url='http://test') as client:
        for _ in range(2):
            response = await client.post('/ai/chat', json={'message':'question'})
            assert response.json()['data']['metadata']['planning_stage'] == 'questions'
        assert (await client.get('/ai/plan-usage')).json()['used'] == 0
        ident = None
        for _ in range(5):
            response = await client.post('/ai/chat', json={'message':'make plan', **({'session_id':ident} if ident else {})})
            assert response.status_code == 200
            ident = response.json()['data']['metadata']['session_id']
            assert response.json()['data']['content'] == 'Day 1: Pune museums'
        assert (await client.get('/ai/plan-usage')).json()['remaining'] == 0
        assert (await client.post('/ai/chat', json={'message':'make plan','session_id':ident})).status_code == 429
        await client.delete('/ai/sessions/'+ident)
        assert (await client.get('/ai/plan-usage')).json()['remaining'] == 0
    await engine.dispose()
