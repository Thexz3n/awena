"""User ORM model."""
import enum
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Language(str, enum.Enum):
    """Supported UI languages."""
    EN = "en"        # English
    CKB = "ckb"      # Kurdish (Sorani / Central) — کوردی


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)

    # Avatar URL (optional). Profile pic is uploaded separately if needed.
    avatar_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # User's preferred UI language: "en" or "ckb"
    language: Mapped[Language] = mapped_column(
        Enum(Language, native_enum=False, length=10),
        default=Language.EN,
        nullable=False,
    )

    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    history = relationship(
        "TranslationHistory",
        back_populates="user",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    password_resets = relationship(
        "PasswordReset",
        back_populates="user",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    refresh_tokens = relationship(
        "RefreshToken",
        back_populates="user",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email!r}>"
