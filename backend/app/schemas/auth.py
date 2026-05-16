"""Pydantic schemas for authentication endpoints."""
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.schemas.user import UserRead, _validate_password


# ─── Tokens ────────────────────────────────────────────────────
class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


# ─── Signup ────────────────────────────────────────────────────
class SignupRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)

    @field_validator("name")
    @classmethod
    def trim(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Name cannot be empty.")
        return v

    @field_validator("password")
    @classmethod
    def strong(cls, v: str) -> str:
        return _validate_password(v)


class SignupResponse(BaseModel):
    success: bool = True
    message: str = "Account created successfully."
    user: UserRead


# ─── Login ─────────────────────────────────────────────────────
class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1)


class LoginResponse(BaseModel):
    success: bool = True
    message: str = "Login successful."
    token: str                  # alias for access_token (kept for Flutter compat)
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserRead


class SocialLoginRequest(BaseModel):
    provider: str  # 'google' or 'facebook'
    token: str


# ─── Refresh ───────────────────────────────────────────────────
class RefreshRequest(BaseModel):
    refresh_token: str


class RefreshResponse(BaseModel):
    success: bool = True
    message: str = "Token refreshed."
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


# ─── Forgot / Reset password ───────────────────────────────────
class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ForgotPasswordResponse(BaseModel):
    success: bool = True
    message: str = "If the email is registered, a reset token has been generated."
    # Returned in dev only. In production, send via email and remove this.
    reset_token: Optional[str] = None


class ResetPasswordRequest(BaseModel):
    token: str = Field(..., min_length=10)
    new_password: str = Field(..., min_length=8, max_length=128)

    @field_validator("new_password")
    @classmethod
    def strong(cls, v: str) -> str:
        return _validate_password(v)
