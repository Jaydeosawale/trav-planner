import asyncio
from datetime import timedelta
import pytest
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from app.services.ai import daily_plans as quota


@pytest.mark.asyncio
async def test_five_completed_plans_account_isolation_reset_and_rollback(monkeypatch):
    engine = create_async_engine('sqlite+aiosqlite:///:memory:')
    async with engine.begin() as conn:
        await conn.run_sync(quota.DailyPlanUsage.__table__.create)
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    today = quota.current_day()
    async with sessions() as db:
        for _ in range(5):
            await quota.check(db, 'one')
            await quota.consume(db, 'one')
            await db.commit()
        assert (await quota.status(db, 'one'))['remaining'] == 0
        with pytest.raises(HTTPException) as blocked:
            await quota.consume(db, 'one')
        assert blocked.value.status_code == 429
        await db.rollback()
        assert (await quota.status(db, 'one'))['used'] == 5
        assert (await quota.status(db, 'other'))['remaining'] == 5
        await quota.consume(db, 'other')
        await db.rollback()  # An unsuccessful save must not consume a plan.
        assert (await quota.status(db, 'other'))['used'] == 0
        monkeypatch.setattr(quota, 'current_day', lambda: today + timedelta(days=1))
        assert (await quota.status(db, 'one'))['remaining'] == 5
    await engine.dispose()


@pytest.mark.asyncio
async def test_concurrent_completions_cannot_exceed_five(tmp_path):
    engine = create_async_engine('sqlite+aiosqlite:///' + str(tmp_path/'quota.db'))
    async with engine.begin() as conn:
        await conn.run_sync(quota.DailyPlanUsage.__table__.create)
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    async def attempt():
        async with sessions() as db:
            try:
                await quota.consume(db, 'one')
                await db.commit()
                return True
            except HTTPException:
                await db.rollback()
                return False
    assert sum(await asyncio.gather(*(attempt() for _ in range(12)))) == 5
    async with sessions() as db:
        assert (await quota.status(db, 'one'))['used'] == 5
    await engine.dispose()


@pytest.mark.asyncio
async def test_plan_usage_requires_sign_in():
    from fastapi import FastAPI
    from httpx import AsyncClient, ASGITransport
    from app.api.v1.ai.router import router
    from app.database.session import get_db
    app = FastAPI(); app.include_router(router, prefix='/ai')
    async def db():
        yield None
    app.dependency_overrides[get_db] = db
    async with AsyncClient(transport=ASGITransport(app=app), base_url='http://test') as client:
        assert (await client.get('/ai/plan-usage')).status_code in (401, 403)
