"""SQLAlchemy database setup and session management."""
import logging

from sqlalchemy import create_engine, text
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import settings

logger = logging.getLogger(__name__)


# ─── Base ORM class ─────────────────────────────────────────────
class Base(DeclarativeBase):
    """Common declarative base for all models."""
    pass


# ─── Engine & Session ───────────────────────────────────────────
engine = create_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_pre_ping=True,        # detects stale connections
    pool_recycle=3600,         # recycle every hour to dodge MySQL wait_timeout
    pool_size=10,
    max_overflow=20,
)

SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)


# ─── Dependency: yield a DB session per request ─────────────────
def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ─── Initialize: create database (if missing) + tables ──────────
def init_db() -> None:
    """Create the MySQL database if it doesn't exist, then create tables."""
    # Ensure the DB exists. Connect without a default DB first.
    bootstrap_engine = create_engine(settings.DATABASE_URL_NO_DB, echo=False)
    try:
        with bootstrap_engine.connect() as conn:
            conn.execute(
                text(
                    f"CREATE DATABASE IF NOT EXISTS `{settings.DB_NAME}` "
                    "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
                )
            )
            conn.commit()
        logger.info("Ensured database '%s' exists.", settings.DB_NAME)
    except Exception as e:
        logger.error("Failed to ensure database exists: %s", e)
        raise
    finally:
        bootstrap_engine.dispose()

    # Import all models so they register on Base.metadata
    from app.models import history, password_reset, refresh_token, user  # noqa: F401

    Base.metadata.create_all(bind=engine)
    logger.info("Database tables initialized.")
