"""Security primitives: password hashing, JWT, secure-token utilities."""
import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import settings

# bcrypt context. `auto` lets us upgrade old hashes silently.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ─── Password hashing ───────────────────────────────────────────
def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return pwd_context.verify(plain, hashed)
    except Exception:
        return False


# ─── JWT ────────────────────────────────────────────────────────
def _create_token(
    subject: str | int,
    token_type: str,
    expires_delta: timedelta,
    extra_claims: Optional[dict] = None,
) -> str:
    now = datetime.now(timezone.utc)
    payload: dict[str, Any] = {
        "sub": str(subject),
        "type": token_type,
        "iat": int(now.timestamp()),
        "exp": int((now + expires_delta).timestamp()),
        "jti": secrets.token_urlsafe(16),
    }
    if extra_claims:
        payload.update(extra_claims)
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_access_token(user_id: int | str, extra: Optional[dict] = None) -> str:
    return _create_token(
        user_id,
        "access",
        timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        extra,
    )


def create_refresh_token(user_id: int | str) -> str:
    return _create_token(
        user_id,
        "refresh",
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )


def decode_token(token: str) -> dict:
    """Decode + validate a JWT. Raises JWTError on any failure."""
    return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])


def safe_decode(token: str) -> Optional[dict]:
    try:
        return decode_token(token)
    except JWTError:
        return None


# ─── Random tokens (password reset) ─────────────────────────────
def generate_reset_token() -> str:
    """Cryptographically random url-safe token (sent to user)."""
    return secrets.token_urlsafe(32)


def hash_token(token: str) -> str:
    """One-way hash for *storing* tokens we sent out.
    We never want the raw token in the DB.
    """
    return hashlib.sha256(token.encode("utf-8")).hexdigest()
