"""Translation history ORM model."""
import enum
from datetime import datetime

from sqlalchemy import (
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class TranslationType(str, enum.Enum):
    SIGN_TO_TEXT = "sign_to_text"
    TEXT_TO_SIGN = "text_to_sign"
    VOICE_TO_SIGN = "voice_to_sign"


class TranslationHistory(Base):
    __tablename__ = "translation_history"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Free-form fields filled by the client
    source_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    translated_text: Mapped[str] = mapped_column(Text, nullable=False)

    type: Mapped[TranslationType] = mapped_column(
        Enum(TranslationType, native_enum=False, length=20),
        nullable=False,
        index=True,
    )

    source_language: Mapped[str | None] = mapped_column(String(20), nullable=True)
    target_language: Mapped[str | None] = mapped_column(String(20), nullable=True)
    confidence: Mapped[float | None] = mapped_column(Float, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )

    user = relationship("User", back_populates="history")
