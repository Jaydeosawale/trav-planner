"""Bcrypt passwords compatible with existing account hashes."""
import bcrypt


def hash_password(password: str) -> str:
    encoded = password.encode('utf-8')
    if len(encoded) > 72:
        raise ValueError('Password exceeds 72 UTF-8 bytes.')
    return bcrypt.hashpw(encoded, bcrypt.gensalt()).decode('ascii')


def verify_password(password: str, password_hash: str) -> bool:
    if len(password.encode('utf-8')) > 72:
        return False
    try:
        return bcrypt.checkpw(password.encode('utf-8'), password_hash.encode('ascii'))
    except (ValueError, TypeError):
        return False
