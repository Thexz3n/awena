"""Pydantic schemas for translation history."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.history import TranslationType


# ─── Create / Read ─────────────────────────────────────────────
class HistoryCreate(BaseModel):
    type: TranslationType
    translated_text: str = Field(..., min_length=1, max_length=5000)
    source_text: Optional[str] = Field(None, max_length=5000)
    source_language: Optional[str] = Field(None, max_length=20)
    target_language: Optional[str] = Field(None, max_length=20)
    confidence: Optional[float] = Field(None, ge=0.0, le=1.0)


class HistoryRead(BaseModel):
    id: int
    type: TranslationType
    translated_text: str
    source_text: Optional[str] = None
    source_language: Optional[str] = None
    target_language: Optional[str] = None
    confidence: Optional[float] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ─── List + stats ──────────────────────────────────────────────
class HistoryListResponse(BaseModel):
    success: bool = True
    total: int
    page: int
    page_size: int
    items: list[HistoryRead]


class HistoryStats(BaseModel):
    total: int
    sign_to_text: int
    text_to_sign: int
    voice_to_sign: int
    last_7_days: int
    sessions_this_month: int
