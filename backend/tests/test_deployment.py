from app.core.settings import Settings


def test_render_database_url_uses_async_driver():
    for url in ('postgres://user:password@host/db', 'postgresql://user:password@host/db'):
        settings = Settings(_env_file=None, JWT_SECRET_KEY='test-only', DATABASE_URL=url)
        assert settings.database_url == 'postgresql+asyncpg://user:password@host/db'


def test_existing_async_url_is_preserved():
    url = 'postgresql+asyncpg://user:password@host/db'
    assert Settings(_env_file=None, JWT_SECRET_KEY='test-only', DATABASE_URL=url).database_url == url


def test_production_origins_are_explicit():
    settings = Settings(_env_file=None, JWT_SECRET_KEY='test-only', ALLOWED_ORIGINS='https://trav-planner.vercel.app', ALLOWED_ORIGIN_REGEX='')
    assert settings.allowed_origins == ['https://trav-planner.vercel.app']
    assert not settings.ALLOWED_ORIGIN_REGEX


def test_neon_url_keeps_tls_and_uses_asyncpg_parameters():
    url = 'postgresql://user:p%40ss@ep-test.neon.tech/neondb?sslmode=require&channel_binding=require'
    normalized = Settings(_env_file=None, JWT_SECRET_KEY='test-only', DATABASE_URL=url).database_url
    assert normalized.startswith('postgresql+asyncpg://user:p%40ss@ep-test.neon.tech/')
    assert 'ssl=verify-full' in normalized
    assert 'sslmode=' not in normalized
    assert 'channel_binding=' not in normalized
