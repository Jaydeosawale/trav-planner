import asyncio
import hashlib
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy import select
from pydantic import ValidationError
from app.modules.auth.model import User, PasswordResetToken
from app.modules.auth.schema import RegisterRequest, LoginRequest
from app.modules.auth.service import AuthService
from app.modules.auth import recovery
from app.common.security.passwords import hash_password, verify_password
from app.common.security.jwt import decode_access_token
from app.common.exceptions.unauthorized import UnauthorizedException
from app.common.exceptions.app_exception import AppException
from app.dependencies.current_user import get_current_user


def test_password_validation_and_email_normalization():
    payload = RegisterRequest(email='Person@EXAMPLE.COM', password='LongEnough123!', full_name='Person')
    assert payload.email == 'person@example.com'
    hashed = hash_password(payload.password)
    assert verify_password(payload.password, hashed)
    assert not verify_password('WrongPassword!', hashed)
    with pytest.raises(ValidationError):
        RegisterRequest(email='person@example.com', password='😀' * 20, full_name='Person')


def test_unknown_and_wrong_password_have_same_login_error():
    async def check():
        service = AuthService()
        service.repository.get_by_email = AsyncMock(return_value=None)
        with pytest.raises(UnauthorizedException) as missing:
            await service.authenticate(None, LoginRequest(email='missing@example.com', password='WrongPassword!'))
        service.repository.get_by_email = AsyncMock(return_value=SimpleNamespace(is_active=True, password_hash=hash_password('CorrectPassword!')))
        with pytest.raises(UnauthorizedException) as wrong:
            await service.authenticate(None, LoginRequest(email='person@example.com', password='WrongPassword!'))
        assert str(missing.value) == str(wrong.value)
    asyncio.run(check())


def test_recovery_delivers_once_and_invalidates_sessions(monkeypatch):
    async def check():
        engine = create_async_engine('sqlite+aiosqlite:///:memory:')
        async with engine.begin() as conn:
            await conn.run_sync(lambda c: User.__table__.create(c))
            await conn.run_sync(lambda c: PasswordResetToken.__table__.create(c))
        session = async_sessionmaker(engine, expire_on_commit=False)
        delivered = []
        monkeypatch.setattr(recovery, 'recovery_available', lambda: True)
        monkeypatch.setattr(recovery, 'send_recovery_email', lambda email, token: delivered.append((email, token)))
        async with session() as db:
            user = User(email='person@example.com', full_name='Person', password_hash=hash_password('OldPassword!'), role='user')
            db.add(user); await db.commit()
            old_tokens = await AuthService().authenticate(db, LoginRequest(email=user.email, password='OldPassword!'))
            await recovery.request_recovery(db, user.email)
            await recovery.request_recovery(db, user.email)
            await recovery.request_recovery(db, 'missing@example.com')
            assert len(delivered) == 1
            token = delivered[0][1]
            record = (await db.execute(select(PasswordResetToken))).scalar_one()
            assert record.token_hash == hashlib.sha256(token.encode()).hexdigest()
            assert record.token_hash != token
            await recovery.confirm_recovery(db, token, 'NewPassword!')
            assert verify_password('NewPassword!', user.password_hash)
            assert user.auth_version == 1
            with pytest.raises(UnauthorizedException):
                await recovery.confirm_recovery(db, token, 'AnotherPassword!')
            with pytest.raises(UnauthorizedException):
                await get_current_user(old_tokens.access_token, db)
            from app.modules.auth.schema import RefreshTokenRequest
            with pytest.raises(UnauthorizedException):
                await AuthService().refresh_access_token(db, RefreshTokenRequest(refresh_token=old_tokens.refresh_token))
            fresh = await AuthService().authenticate(db, LoginRequest(email=user.email, password='NewPassword!'))
            assert decode_access_token(fresh.access_token)['ver'] == 1
            expired = PasswordResetToken(user_id=user.id, token_hash=hashlib.sha256(b'expired-token').hexdigest(), expires_at=datetime.now(timezone.utc) - timedelta(minutes=1))
            db.add(expired); await db.commit()
            with pytest.raises(UnauthorizedException):
                await recovery.confirm_recovery(db, 'expired-token', 'NewPassword!')
        await engine.dispose()
    asyncio.run(check())


def test_delivery_failure_never_claims_success(monkeypatch):
    async def check():
        monkeypatch.setattr(recovery, 'recovery_available', lambda: False)
        with pytest.raises(AppException) as unavailable:
            await recovery.request_recovery(None, 'person@example.com')
        assert unavailable.value.status_code == 503
    asyncio.run(check())
