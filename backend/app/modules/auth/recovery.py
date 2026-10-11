"""Single-use password recovery with private SMTP delivery."""
import asyncio
import httpx
import hashlib
import secrets
import smtplib
import ssl
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
from urllib.parse import quote

from sqlalchemy import select, update
from app.core.settings import settings
from app.modules.auth.model import User, PasswordResetToken
from app.common.exceptions.app_exception import AppException
from app.common.exceptions.unauthorized import UnauthorizedException
from app.common.security.passwords import hash_password


def recovery_available() -> bool:
    return bool(settings.RECOVERY_MAIL_URL and settings.RECOVERY_MAIL_SECRET) or bool(settings.SMTP_HOST and settings.SMTP_USERNAME and settings.SMTP_PASSWORD and settings.SMTP_FROM_EMAIL)


def send_recovery_email(email: str, token: str) -> None:
    if settings.RECOVERY_MAIL_URL:
        if not settings.RECOVERY_MAIL_URL.startswith('https://'):
            raise ValueError('Recovery delivery requires HTTPS.')
        with httpx.Client(timeout=25) as client:
            response = client.post(settings.RECOVERY_MAIL_URL,
                headers={'Authorization': 'Bearer ' + settings.RECOVERY_MAIL_SECRET},
                json={'email': email, 'token': token})
            response.raise_for_status()
        return
    message = EmailMessage()
    message['From'] = settings.SMTP_FROM_EMAIL
    message['To'] = email
    message['Subject'] = 'Choose a new password for trav.'
    link = settings.FRONTEND_URL.rstrip('/') + '/#reset_token=' + quote(token)
    message.set_content(
        f'Choose your trav. password using this link:\n\n{link}\n\n'
        f'This link expires in {settings.PASSWORD_RESET_MINUTES} minutes and can be used once. '
        'If you did not request it, you can ignore this email.'
    )
    context = ssl.create_default_context()
    if settings.SMTP_PORT == 465:
        with smtplib.SMTP_SSL(settings.SMTP_HOST, settings.SMTP_PORT, context=context, timeout=20) as smtp:
            smtp.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
            smtp.send_message(message)
    else:
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=20) as smtp:
            smtp.starttls(context=context)
            smtp.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
            smtp.send_message(message)


async def request_recovery(db, email: str) -> None:
    if not recovery_available():
        raise AppException('Password recovery is temporarily unavailable. Please try again later.', 503, 'RECOVERY_UNAVAILABLE')
    user = (await db.execute(select(User).where(User.email == email, User.is_deleted.is_(False)).with_for_update())).scalar_one_or_none()
    if user is None or not user.is_active:
        return
    now = datetime.now(timezone.utc)
    recent = (await db.execute(select(PasswordResetToken).where(
        PasswordResetToken.user_id == user.id,
        PasswordResetToken.created_at > now - timedelta(minutes=2),
    ).limit(1))).scalar_one_or_none()
    if recent is not None:
        return
    token = secrets.token_urlsafe(48)
    db.add(PasswordResetToken(user_id=user.id, token_hash=hashlib.sha256(token.encode()).hexdigest(),
        expires_at=now + timedelta(minutes=settings.PASSWORD_RESET_MINUTES)))
    try:
        await asyncio.to_thread(send_recovery_email, user.email, token)
        await db.commit()
    except Exception as exc:
        await db.rollback()
        raise AppException('We could not send a recovery email. Please try again later.', 503, 'RECOVERY_UNAVAILABLE') from exc


async def confirm_recovery(db, token: str, password: str) -> None:
    now = datetime.now(timezone.utc)
    record = (await db.execute(select(PasswordResetToken).where(
        PasswordResetToken.token_hash == hashlib.sha256(token.encode()).hexdigest(),
        PasswordResetToken.used_at.is_(None), PasswordResetToken.expires_at > now,
    ).with_for_update())).scalar_one_or_none()
    if record is None:
        raise UnauthorizedException('This recovery link is invalid or expired. Request a new one.')
    user = (await db.execute(select(User).where(User.id == record.user_id,
        User.is_deleted.is_(False), User.is_active.is_(True)).with_for_update())).scalar_one_or_none()
    if user is None:
        raise UnauthorizedException('This recovery link is invalid or expired. Request a new one.')
    user.password_hash = hash_password(password)
    user.auth_version += 1
    await db.execute(update(PasswordResetToken).where(PasswordResetToken.user_id == user.id,
        PasswordResetToken.used_at.is_(None)).values(used_at=now))
    await db.commit()
