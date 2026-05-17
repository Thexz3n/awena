"""Business logic for authentication."""
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    generate_reset_token,
    hash_password,
    hash_token,
    verify_password,
)
import requests
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from app.models.password_reset import PasswordReset
from app.models.refresh_token import RefreshToken
from app.models.user import User


def _ensure_aware(dt: datetime) -> datetime:
    """Normalize a datetime to UTC-aware. SQLite returns naive; MySQL returns aware.
    Either way we treat the stored value as UTC."""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


class AuthService:
    def __init__(self, db: Session):
        self.db = db

    # ─── Signup ────────────────────────────────────────────────
    def signup(self, name: str, email: str, password: str) -> User:
        email_norm = email.strip().lower()
        existing = self.db.query(User).filter(User.email == email_norm).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An account with this email already exists.",
            )
        user = User(
            name=name.strip(),
            email=email_norm,
            password_hash=hash_password(password),
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    # ─── Login ─────────────────────────────────────────────────
    def authenticate(self, email: str, password: str) -> User:
        user = (
            self.db.query(User)
            .filter(User.email == email.strip().lower())
            .first()
        )
        # We don't reveal whether email exists.
        if not user or not verify_password(password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password.",
            )
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is disabled.",
            )
        return user

    # ─── Social Auth ───────────────────────────────────────────
    async def authenticate_social(self, provider: str, token: str) -> User:
        """Verify social token, get profile, and find/create user."""
        email = ""
        name = ""

        if provider == "google":
            try:
                # 1. Try validating as an ID Token first
                idinfo = id_token.verify_oauth2_token(
                    token, google_requests.Request(), settings.GOOGLE_CLIENT_ID
                )
                email = idinfo["email"]
                name = idinfo.get("name", email.split("@")[0])
            except Exception as e_id:
                # 2. Fallback: Try validating as an Access Token via Google UserInfo API
                try:
                    resp = requests.get(
                        "https://www.googleapis.com/oauth2/v3/userinfo",
                        headers={"Authorization": f"Bearer {token}"}
                    )
                    if resp.status_code != 200:
                        raise Exception("Google UserInfo API verification failed")
                    user_data = resp.json()
                    email = user_data["email"]
                    name = user_data.get("name", email.split("@")[0])
                except Exception as e_access:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail=f"Invalid Google token (tried ID and Access token): ID Error: {str(e_id)} | Access Error: {str(e_access)}",
                    )

        elif provider == "facebook":
            # Facebook Graph API verification
            try:
                # We verify the token by calling the 'me' endpoint
                resp = requests.get(
                    "https://graph.facebook.com/me",
                    params={"fields": "id,name,email", "access_token": token},
                )
                if resp.status_code != 200:
                    raise Exception("Facebook verification failed")
                fb_data = resp.json()
                email = fb_data.get("email")
                if not email:
                    # Some FB accounts don't have email; we use ID as fallback email
                    email = f"{fb_data['id']}@facebook.com"
                name = fb_data.get("name", email.split("@")[0])
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail=f"Invalid Facebook token: {str(e)}",
                )
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unsupported social provider.",
            )

        # Find or create user
        user = self.db.query(User).filter(User.email == email.lower()).first()
        if not user:
            user = User(
                name=name,
                email=email.lower(),
                password_hash="",  # Social users don't have a local password
                is_active=True,
            )
            self.db.add(user)
            self.db.commit()
            self.db.refresh(user)
        
        if not user.is_active:
             raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is disabled.",
            )
            
        return user

    # ─── Token issuance ────────────────────────────────────────
    def issue_tokens(self, user: User) -> tuple[str, str]:
        access = create_access_token(user.id, extra={"email": user.email})
        refresh = create_refresh_token(user.id)
        # Persist the refresh token (hashed) so we can revoke it.
        self.db.add(
            RefreshToken(
                user_id=user.id,
                token_hash=hash_token(refresh),
                expires_at=datetime.now(timezone.utc)
                + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
            )
        )
        self.db.commit()
        return access, refresh

    # ─── Refresh ───────────────────────────────────────────────
    def refresh_tokens(self, refresh_token: str) -> tuple[str, str, User]:
        try:
            payload = decode_token(refresh_token)
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token.",
            )
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Wrong token type.",
            )

        token_hash = hash_token(refresh_token)
        stored = (
            self.db.query(RefreshToken)
            .filter(RefreshToken.token_hash == token_hash)
            .first()
        )
        if not stored or stored.revoked:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token revoked or unknown.",
            )
        if _ensure_aware(stored.expires_at) < datetime.now(timezone.utc):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token expired.",
            )

        user = self.db.query(User).filter(User.id == stored.user_id).first()
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found.",
            )

        # Rotate: revoke the old refresh token and issue a new pair.
        stored.revoked = True
        self.db.commit()
        new_access, new_refresh = self.issue_tokens(user)
        return new_access, new_refresh, user

    # ─── Logout ────────────────────────────────────────────────
    def logout(self, refresh_token: Optional[str], user_id: int) -> None:
        """Revoke the supplied refresh token (or all of the user's tokens if none)."""
        q = self.db.query(RefreshToken).filter(
            RefreshToken.user_id == user_id, RefreshToken.revoked == False  # noqa: E712
        )
        if refresh_token:
            q = q.filter(RefreshToken.token_hash == hash_token(refresh_token))
        for tok in q.all():
            tok.revoked = True
        self.db.commit()

    # ─── Forgot / Reset password ───────────────────────────────
    def create_password_reset(self, email: str) -> tuple[Optional[User], Optional[str]]:
        """Create a single-use reset token. Returns (user, raw_token) or (None, None)
        if the email is not registered. Caller decides whether to leak that info."""
        user = (
            self.db.query(User)
            .filter(User.email == email.strip().lower())
            .first()
        )
        if not user:
            return None, None

        raw = generate_reset_token()
        self.db.add(
            PasswordReset(
                user_id=user.id,
                token_hash=hash_token(raw),
                expires_at=datetime.now(timezone.utc)
                + timedelta(minutes=settings.RESET_TOKEN_EXPIRE_MINUTES),
            )
        )
        self.db.commit()
        return user, raw

    def reset_password(self, raw_token: str, new_password: str) -> User:
        token_hash = hash_token(raw_token)
        record = (
            self.db.query(PasswordReset)
            .filter(PasswordReset.token_hash == token_hash)
            .order_by(PasswordReset.id.desc())
            .first()
        )
        if not record or record.used:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or already used reset token.",
            )
        if _ensure_aware(record.expires_at) < datetime.now(timezone.utc):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Reset token has expired.",
            )

        user = self.db.query(User).filter(User.id == record.user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid token.",
            )

        user.password_hash = hash_password(new_password)
        record.used = True

        # Revoke all of this user's refresh tokens — defense in depth.
        for tok in user.refresh_tokens:
            tok.revoked = True

        self.db.commit()
        self.db.refresh(user)
        return user
