"""Pydantic schemas for the User resource."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.models.user import Language

# ─── Reusable validators ───────────────────────────────────────


def _validate_password(v: str) -> str:
    if len(v) < 8:
        raise ValueError("Password must be at least 8 characters long.")
    if not any(c.isdigit() for c in v):
        raise ValueError("Password must contain at least one digit.")
    if not any(c.isalpha() for c in v):
        raise ValueError("Password must contain at least one letter.")
    return v


# ─── Schemas ───────────────────────────────────────────────────
class UserRead(BaseModel):
    id: int
    name: str
    email: EmailStr
    avatar_url: Optional[str] = None
    language: Language
    is_verified: bool
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserUpdate(BaseModel):
    """Patch payload for /users/me. All fields optional."""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    avatar_url: Optional[str] = Field(None, max_length=500)
    language: Optional[Language] = None


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=8, max_length=128)

    @field_validator("new_password")
    @classmethod
    def strong(cls, v: str) -> str:
        return _validate_password(v)
