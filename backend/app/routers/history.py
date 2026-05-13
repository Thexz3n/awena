"""Translation-history routes."""
from typing import Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.history import TranslationType
from app.models.user import User
from app.schemas.common import APIResponse
from app.schemas.history import (
    HistoryCreate,
    HistoryListResponse,
    HistoryRead,
    HistoryStats,
)
from app.services.history_service import HistoryService

router = APIRouter(prefix="/history", tags=["history"])


# ─── List ───────────────────────────────────────────────────────
@router.get(
    "",
    response_model=HistoryListResponse,
    summary="List the user's translation history (paginated)",
)
async def list_history(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    type: Optional[TranslationType] = Query(None, description="Filter by translation type"),
    search: Optional[str] = Query(None, max_length=200),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    total, items = HistoryService(db).list(
        user, page=page, page_size=page_size, type_filter=type, search=search
    )
    return HistoryListResponse(
        success=True,
        total=total,
        page=page,
        page_size=page_size,
        items=[HistoryRead.model_validate(i) for i in items],
    )


# ─── Stats ──────────────────────────────────────────────────────
@router.get(
    "/stats",
    response_model=HistoryStats,
    summary="Aggregate stats for the history screen",
)
async def history_stats(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return HistoryStats(**HistoryService(db).stats(user))


# ─── Create ─────────────────────────────────────────────────────
@router.post(
    "",
    response_model=HistoryRead,
    status_code=status.HTTP_201_CREATED,
    summary="Save a new translation history entry",
)
async def create_history(
    payload: HistoryCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    item = HistoryService(db).create(user, payload)
    return HistoryRead.model_validate(item)


# ─── Get one ────────────────────────────────────────────────────
@router.get(
    "/{item_id}",
    response_model=HistoryRead,
    summary="Get a single history item",
)
async def get_history(
    item_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return HistoryRead.model_validate(HistoryService(db).get(user, item_id))


# ─── Delete one ─────────────────────────────────────────────────
@router.delete(
    "/{item_id}",
    response_model=APIResponse,
    summary="Delete one history item",
)
async def delete_history(
    item_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    HistoryService(db).delete(user, item_id)
    return APIResponse(success=True, message="History item deleted.")


# ─── Clear all ──────────────────────────────────────────────────
@router.delete(
    "",
    response_model=APIResponse,
    summary="Clear ALL history for the current user",
)
async def clear_history(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    deleted = HistoryService(db).clear_all(user)
    return APIResponse(
        success=True,
        message=f"Cleared {deleted} history item(s).",
    )
