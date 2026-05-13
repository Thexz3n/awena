"""User-profile business logic."""
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import hash_password, verify_password
from app.models.user import User
from app.schemas.user import UserUpdate


class UserService:
    def __init__(self, db: Session):
        self.db = db

    def update_profile(self, user: User, payload: UserUpdate) -> User:
        data = payload.model_dump(exclude_unset=True)
        if "name" in data:
            user.name = data["name"].strip()
        if "avatar_url" in data:
            user.avatar_url = data["avatar_url"]
        if "language" in data:
            user.language = data["language"]
        self.db.commit()
        self.db.refresh(user)
        return user

    def change_password(self, user: User, current: str, new: str) -> None:
        if not verify_password(current, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password is incorrect.",
            )
        if verify_password(new, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="New password must differ from the current one.",
            )
        user.password_hash = hash_password(new)
        # Revoke all refresh tokens — force re-login on other devices.
        for tok in user.refresh_tokens:
            tok.revoked = True
        self.db.commit()

    def delete_account(self, user: User) -> None:
        self.db.delete(user)
        self.db.commit()
