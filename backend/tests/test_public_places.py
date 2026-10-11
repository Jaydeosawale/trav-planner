"""Public discovery must reach places, without authentication or planner routes."""
from unittest.mock import AsyncMock, patch

from fastapi.testclient import TestClient

from app.database.session import get_db
from app.main import app


def test_public_place_search_is_mounted_and_anonymous():
    async def fake_db():
        yield object()

    app.dependency_overrides[get_db] = fake_db
    try:
        with patch('app.modules.place.router.service.search', new_callable=AsyncMock) as search:
            search.return_value = ([], 0)
            response = TestClient(app).get('/api/v1/places/search?city_id=pune&size=100')
            assert response.status_code == 200
            assert response.json()['data']['items'] == []
            assert search.call_args.kwargs['city_id'] == 'pune'
    finally:
        app.dependency_overrides.pop(get_db, None)


def test_places_namespace_contains_no_planner_writes():
    schema = app.openapi()
    assert '/api/v1/places/search' in schema['paths']
    assert 'post' not in schema['paths']['/api/v1/places/']
