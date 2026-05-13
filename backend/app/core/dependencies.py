"""Common FastAPI dependencies, e.g. extract the current user from a JWT."""
from fastapi import Depends, HTTPException, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy.orm import Session

from app.core.security import decode_token
from app.database import get_db
from app.models.user import User

bearer_scheme = HTTPBearer(auto_error=False)


def _credentials_error(detail: str = "Could not validate credentials") -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )


def get_current_user(
    creds: HTTPAuthorizationCredentials | None = Security(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    """Resolve the authenticated user from an `Authorization: Bearer <token>` header."""
    if creds is None or not creds.credentials:
        raise _credentials_error("Authentication required.")

    try:
        payload = decode_token(creds.credentials)
    except JWTError:
        raise _credentials_error("Invalid or expired token.")

    if payload.get("type") != "access":
        raise _credentials_error("Wrong token type.")

    user_id_raw = payload.get("sub")
    if not user_id_raw:
        raise _credentials_error()

    try:
        user_id = int(user_id_raw)
    except (TypeError, ValueError):
        raise _credentials_error()

    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise _credentials_error("User not found.")
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is disabled.",
        )
    return user


def get_current_active_user(
    user: User = Depends(get_current_user),
) -> User:
    return user
