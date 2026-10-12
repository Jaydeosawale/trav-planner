from types import SimpleNamespace
from datetime import datetime, timedelta, timezone
import httpx
import pytest
from app.services.ai import free_runtime
from app.services.ai.routing import connection_status, RoutingUpdate
from app.integrations.llm.base import LLMResponse
from app.integrations.llm.openai_provider import OpenAIProvider


def test_key_alone_does_not_authorize_openai():
    settings = SimpleNamespace(
        OPENAI_API_KEY="present",
        OPENAI_FREE_ACCESS_UNTIL="",
        GROQ_API_KEY="present",
        GEMINI_API_KEY="present",
    )
    assert not connection_status(settings)["openai"]["eligible"]
    settings.OPENAI_FREE_ACCESS_UNTIL = (
        datetime.now(timezone.utc) - timedelta(seconds=1)
    ).isoformat()
    assert not connection_status(settings)["openai"]["eligible"]
    settings.OPENAI_FREE_ACCESS_UNTIL = (
        datetime.now(timezone.utc) + timedelta(hours=1)
    ).isoformat()
    assert connection_status(settings)["openai"]["eligible"]
    with pytest.raises(ValueError):
        RoutingUpdate(provider_order=["groq", "groq"])
    with pytest.raises(ValueError):
        RoutingUpdate(provider_order=["unknown"])


@pytest.mark.asyncio
async def test_free_fallback_and_emergency_stop(monkeypatch):
    order = RoutingUpdate(provider_order=["openai", "groq", "gemini"])

    async def config():
        return order

    monkeypatch.setattr(free_runtime, "configuration", config)
    monkeypatch.setattr(
        free_runtime,
        "connection_status",
        lambda: {p: {"eligible": True} for p in order.provider_order},
    )
    monkeypatch.setattr(free_runtime, "cooldowns", {})

    async def record(*args, **kwargs):
        pass

    monkeypatch.setattr(free_runtime, "record", record)

    class Provider:
        def __init__(self, name):
            self.name = name

        async def generate(self, **kwargs):
            if self.name == "openai":
                response = httpx.Response(
                    429,
                    request=httpx.Request(
                        "POST", "https://api.openai.com/v1/responses"
                    ),
                )
                raise httpx.HTTPStatusError(
                    "quota", request=response.request, response=response
                )
            return LLMResponse(content="Plan", provider=self.name, model="test")

    monkeypatch.setattr(
        free_runtime, "get_llm_provider", lambda name, **kwargs: Provider(name)
    )
    response, _, attempts = await free_runtime.run("generate", prompt="Trip")
    assert response.provider == "groq" and attempts == ["openai", "groq"]
    _, _, attempts = await free_runtime.run("generate", prompt="Trip")
    assert attempts == ["groq"]  # cooldown retained across requests
    order.enabled = False
    response, reason, attempts = await free_runtime.run("generate", prompt="Trip")
    assert response is None and attempts == [] and "paused" in reason


@pytest.mark.asyncio
async def test_tool_continuation_never_changes_provider(monkeypatch):
    async def config():
        return RoutingUpdate(provider_order=["gemini"])

    monkeypatch.setattr(free_runtime, "configuration", config)
    monkeypatch.setattr(
        free_runtime,
        "connection_status",
        lambda: {"groq": {"eligible": True}, "gemini": {"eligible": True}},
    )
    response, _, attempts = await free_runtime.run(
        "continue_with_tool_results", forced_provider="groq"
    )
    assert response is None and attempts == []


@pytest.mark.asyncio
async def test_responses_tools_usage_and_continuation():
    bodies = []

    def handle(request):
        import json

        body = json.loads(request.content)
        bodies.append(body)
        assert body["store"] is False
        assert body["tools"][0]["name"] == "place_search"
        if len(bodies) == 1:
            return httpx.Response(
                200,
                json={
                    "status": "completed",
                    "model": "test",
                    "output": [
                        {
                            "type": "function_call",
                            "call_id": "call-1",
                            "name": "place_search",
                            "arguments": '{"search":"Pune"}',
                        }
                    ],
                    "usage": {
                        "input_tokens": 10,
                        "output_tokens": 4,
                        "total_tokens": 14,
                    },
                },
            )
        assert body["input"][0]["content"] == "Visit Pune"
        assert body["input"][-1]["call_id"] == "call-1"
        return httpx.Response(
            200,
            json={
                "status": "completed",
                "output": [
                    {
                        "type": "message",
                        "content": [
                            {"type": "output_text", "text": "Visit the museum"}
                        ],
                    }
                ],
            },
        )

    async with httpx.AsyncClient(transport=httpx.MockTransport(handle)) as client:
        provider = OpenAIProvider(api_key="test-only", model="test", client=client)
        tools = [
            {"name": "place_search", "parameters": {"type": "object", "properties": {}}}
        ]
        response = await provider.generate_with_tools("Visit Pune", tools=tools)
        assert (
            response.tool_calls[0].arguments == {"search": "Pune"}
            and response.usage.total_tokens == 14
        )
        final = await provider.continue_with_tool_results(
            response=response, tool_results=[{"places": []}], tools=tools
        )
        assert final.content == "Visit the museum"


def test_routing_migration_preserves_existing_tables():
    import importlib.util
    from pathlib import Path
    from sqlalchemy import create_engine, text
    from alembic.migration import MigrationContext
    from alembic.operations import Operations

    path = Path(__file__).parents[1] / "alembic/versions/f92c48e6bd35_ai_routing.py"
    spec = importlib.util.spec_from_file_location("routing_migration", path)
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    engine = create_engine("sqlite:///:memory:")
    with engine.begin() as connection:
        connection.execute(text("CREATE TABLE existing_trips (title TEXT)"))
        connection.execute(text("INSERT INTO existing_trips VALUES ('Keep my trip')"))
        with Operations.context(MigrationContext.configure(connection)):
            migration.upgrade()
        assert (
            connection.execute(
                text("SELECT provider_order FROM ai_routing_settings")
            ).scalar()
            == '["openai","groq","gemini"]'
        )
        assert (
            connection.execute(text("SELECT title FROM existing_trips")).scalar()
            == "Keep my trip"
        )
    engine.dispose()


def test_groq_blank_model_uses_a_supported_default(monkeypatch):
    from app.integrations.llm import groq
    monkeypatch.setattr(groq, 'get_settings', lambda: SimpleNamespace(GROQ_API_KEY='test-only', GROQ_MODEL=''))
    provider = groq.GroqProvider()
    assert provider.model_name == 'openai/gpt-oss-20b'

@pytest.mark.asyncio
async def test_usage_writer_matches_the_deployed_migration(monkeypatch):
    import importlib.util
    from pathlib import Path
    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
    from alembic.migration import MigrationContext
    from alembic.operations import Operations
    path=Path(__file__).parents[1]/'alembic/versions/f92c48e6bd35_ai_routing.py'
    spec=importlib.util.spec_from_file_location('deployed_routing_migration',path)
    migration=importlib.util.module_from_spec(spec);spec.loader.exec_module(migration)
    engine=create_async_engine('sqlite+aiosqlite:///:memory:')
    def create_schema(connection):
        with Operations.context(MigrationContext.configure(connection)):
            migration.upgrade()
    async with engine.begin() as connection:
        await connection.run_sync(create_schema)
    sessions=async_sessionmaker(engine,expire_on_commit=False)
    monkeypatch.setattr(free_runtime,'SessionLocal',sessions)
    await free_runtime.record('groq',response=LLMResponse(content='Plan',provider='groq',model='test'))
    async with sessions() as db:
        assert (await db.execute(text('SELECT count(*) FROM ai_usage_records'))).scalar()==1
    await engine.dispose()
