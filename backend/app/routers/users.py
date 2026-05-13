"""User profile routes."""
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.common import APIResponse
from app.schemas.user import ChangePasswordRequest, UserRead, UserUpdate
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["users"])


# ─── Get current user ───────────────────────────────────────────
@router.get(
    "/me",
    response_model=UserRead,
    summary="Get the currently authenticated user",
)
async def read_me(user: User = Depends(get_current_user)):
    return UserRead.model_validate(user)


# ─── Update profile ─────────────────────────────────────────────
@router.patch(
    "/me",
    response_model=UserRead,
    summary="Update profile (name, avatar, language)",
)
async def update_me(
    payload: UserUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    updated = UserService(db).update_profile(user, payload)
    return UserRead.model_validate(updated)


# ─── Change password ────────────────────────────────────────────
@router.patch(
    "/me/password",
    response_model=APIResponse,
    summary="Change the current user's password",
)
async def change_password(
    payload: ChangePasswordRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    UserService(db).change_password(user, payload.current_password, payload.new_password)
    return APIResponse(
        success=True,
        message="Password changed successfully. Please sign in again on other devices.",
    )


# ─── Delete account ─────────────────────────────────────────────
@router.delete(
    "/me",
    response_model=APIResponse,
    status_code=status.HTTP_200_OK,
    summary="Permanently delete the current user's account",
)
async def delete_me(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    UserService(db).delete_account(user)
    return APIResponse(success=True, message="Account deleted.")
