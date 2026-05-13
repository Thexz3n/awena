"""Translation history business logic."""
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.models.history import TranslationHistory, TranslationType
from app.models.user import User
from app.schemas.history import HistoryCreate


class HistoryService:
    def __init__(self, db: Session):
        self.db = db

    # ─── Create ────────────────────────────────────────────────
    def create(self, user: User, payload: HistoryCreate) -> TranslationHistory:
        item = TranslationHistory(
            user_id=user.id,
            type=payload.type,
            translated_text=payload.translated_text,
            source_text=payload.source_text,
            source_language=payload.source_language,
            target_language=payload.target_language,
            confidence=payload.confidence,
        )
        self.db.add(item)
        self.db.commit()
        self.db.refresh(item)
        return item

    # ─── List + filter + paginate ──────────────────────────────
    def list(
        self,
        user: User,
        page: int = 1,
        page_size: int = 20,
        type_filter: Optional[TranslationType] = None,
        search: Optional[str] = None,
    ) -> tuple[int, list[TranslationHistory]]:
        page = max(1, page)
        page_size = max(1, min(100, page_size))

        q = self.db.query(TranslationHistory).filter(
            TranslationHistory.user_id == user.id
        )
        if type_filter is not None:
            q = q.filter(TranslationHistory.type == type_filter)
        if search:
            term = f"%{search.strip()}%"
            q = q.filter(
                or_(
                    TranslationHistory.translated_text.like(term),
                    TranslationHistory.source_text.like(term),
                )
            )

        total = q.count()
        items = (
            q.order_by(TranslationHistory.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
            .all()
        )
        return total, items

    # ─── Get one ───────────────────────────────────────────────
    def get(self, user: User, item_id: int) -> TranslationHistory:
        item = (
            self.db.query(TranslationHistory)
            .filter(
                TranslationHistory.id == item_id,
                TranslationHistory.user_id == user.id,
            )
            .first()
        )
        if not item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="History item not found.",
            )
        return item

    # ─── Delete one ────────────────────────────────────────────
    def delete(self, user: User, item_id: int) -> None:
        item = self.get(user, item_id)
        self.db.delete(item)
        self.db.commit()

    # ─── Clear all ─────────────────────────────────────────────
    def clear_all(self, user: User) -> int:
        count = (
            self.db.query(TranslationHistory)
            .filter(TranslationHistory.user_id == user.id)
            .delete(synchronize_session=False)
        )
        self.db.commit()
        return count

    # ─── Stats ─────────────────────────────────────────────────
    def stats(self, user: User) -> dict:
        base = self.db.query(TranslationHistory).filter(
            TranslationHistory.user_id == user.id
        )
        total = base.count()

        def count_type(t: TranslationType) -> int:
            return base.filter(TranslationHistory.type == t).count()

        sign_to_text = count_type(TranslationType.SIGN_TO_TEXT)
        text_to_sign = count_type(TranslationType.TEXT_TO_SIGN)
        voice_to_sign = count_type(TranslationType.VOICE_TO_SIGN)

        now = datetime.now(timezone.utc)
        last_7_days = base.filter(
            TranslationHistory.created_at >= now - timedelta(days=7)
        ).count()

        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        sessions_this_month = base.filter(
            TranslationHistory.created_at >= month_start
        ).count()

        return {
            "total": total,
            "sign_to_text": sign_to_text,
            "text_to_sign": text_to_sign,
            "voice_to_sign": voice_to_sign,
            "last_7_days": last_7_days,
            "sessions_this_month": sessions_this_month,
        }
