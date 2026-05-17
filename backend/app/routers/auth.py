"""Authentication routes."""
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.config import settings
from app.core.dependencies import get_current_user
from app.core.limiter import limiter
from app.database import get_db
from app.models.user import User
from app.schemas.auth import (
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    LoginRequest,
    LoginResponse,
    RefreshRequest,
    RefreshResponse,
    ResetPasswordRequest,
    SignupRequest,
    SignupResponse,
    SocialLoginRequest,
)
from app.schemas.common import APIResponse
from app.schemas.user import UserRead
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


# ─── Signup ─────────────────────────────────────────────────────
@router.post(
    "/signup",
    response_model=SignupResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new user account",
)
@limiter.limit(settings.RATE_LIMIT_SIGNUP)
async def signup(
    request: Request,
    payload: SignupRequest,
    db: Session = Depends(get_db),
):
    user = AuthService(db).signup(payload.name, payload.email, payload.password)
    return SignupResponse(
        success=True,
        message="Account created successfully.",
        user=UserRead.model_validate(user),
    )


# ─── Login ──────────────────────────────────────────────────────
@router.post(
    "/login",
    response_model=LoginResponse,
    summary="Authenticate and obtain tokens",
)
@limiter.limit(settings.RATE_LIMIT_LOGIN)
async def login(
    request: Request,
    payload: LoginRequest,
    db: Session = Depends(get_db),
):
    svc = AuthService(db)
    user = svc.authenticate(payload.email, payload.password)
    access, refresh = svc.issue_tokens(user)
    return LoginResponse(
        success=True,
        message="Login successful.",
        token=access,                # Flutter compatibility (legacy field name)
        access_token=access,
        refresh_token=refresh,
        user=UserRead.model_validate(user),
    )


# ─── Social Login ───────────────────────────────────────────────
@router.post(
    "/social",
    response_model=LoginResponse,
    summary="Authenticate via social provider (Google/Facebook)",
)
async def social_login(
    payload: SocialLoginRequest,
    db: Session = Depends(get_db),
):
    svc = AuthService(db)
    user = await svc.authenticate_social(payload.provider, payload.token)
    access, refresh = svc.issue_tokens(user)
    return LoginResponse(
        success=True,
        message="Social login successful.",
        token=access,
        access_token=access,
        refresh_token=refresh,
        user=UserRead.model_validate(user),
    )


# ─── Refresh ────────────────────────────────────────────────────
@router.post(
    "/refresh",
    response_model=RefreshResponse,
    summary="Rotate the access + refresh tokens",
)
async def refresh(
    payload: RefreshRequest,
    db: Session = Depends(get_db),
):
    new_access, new_refresh, _ = AuthService(db).refresh_tokens(payload.refresh_token)
    return RefreshResponse(
        access_token=new_access,
        refresh_token=new_refresh,
    )


# ─── Logout ─────────────────────────────────────────────────────
@router.post(
    "/logout",
    response_model=APIResponse,
    summary="Revoke the user's refresh token(s)",
)
async def logout(
    payload: RefreshRequest | None = None,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    AuthService(db).logout(
        refresh_token=payload.refresh_token if payload else None,
        user_id=user.id,
    )
    return APIResponse(success=True, message="Logged out successfully.")


# ─── Forgot password ────────────────────────────────────────────
@router.post(
    "/forgot-password",
    response_model=ForgotPasswordResponse,
    summary="Request a password-reset token",
)
@limiter.limit(settings.RATE_LIMIT_FORGOT)
async def forgot_password(
    request: Request,
    payload: ForgotPasswordRequest,
    db: Session = Depends(get_db),
):
    user, raw = AuthService(db).create_password_reset(payload.email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email address not registered."
        )

    # Send the reset email (real email if SMTP configured, else prints to console)
    from app.core.email import send_reset_email
    send_reset_email(to_email=user.email, name=user.name, token=raw)

    return ForgotPasswordResponse(
        success=True,
        message="A password reset token has been sent to your email address.",
        reset_token=raw if settings.DEBUG else None,
    )


# ─── Reset password ─────────────────────────────────────────────
@router.post(
    "/reset-password",
    response_model=APIResponse,
    summary="Set a new password using a reset token",
)
async def reset_password(
    payload: ResetPasswordRequest,
    db: Session = Depends(get_db),
):
    AuthService(db).reset_password(payload.token, payload.new_password)
    return APIResponse(success=True, message="Password successfully reset.")
