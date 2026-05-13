"""
Signslator FastAPI Backend
==========================
Production-ready REST API for the Signslator Flutter app.

Features
--------
- JWT auth (access + refresh tokens)
- bcrypt password hashing
- MySQL via SQLAlchemy 2.0
- Rate limiting via SlowAPI
- CORS configured per-environment
- Strict input validation via Pydantic v2
- Centralized exception handling
- Auto-creates the database & tables on startup

Run locally:
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

Docs:
    http://localhost:8000/docs
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from sqlalchemy.exc import SQLAlchemyError

from app.config import settings
from app.core.limiter import limiter
from app.database import init_db
from app.routers import auth_router, history_router, users_router


# ─── Lifespan (startup/shutdown) ────────────────────────────────
@asynccontextmanager
async def lifespan(_: FastAPI):
    """Initialize DB schema on startup."""
    init_db()
    yield


# ─── App factory ────────────────────────────────────────────────
def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version="1.0.0",
        description="Backend API for the Signslator sign-language translation app.",
        debug=settings.DEBUG,
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
    )

    # Rate limiter
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    # CORS
    origins = (
        ["*"]
        if "*" in settings.CORS_ORIGINS_LIST
        else settings.CORS_ORIGINS_LIST
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ─── Routers ────────────────────────────────────────────────
    app.include_router(auth_router, prefix=settings.API_V1_PREFIX)
    app.include_router(users_router, prefix=settings.API_V1_PREFIX)
    app.include_router(history_router, prefix=settings.API_V1_PREFIX)

    # ─── Root & health ──────────────────────────────────────────
    @app.get("/", tags=["meta"])
    async def root():
        return {
            "name": settings.APP_NAME,
            "version": "1.0.0",
            "status": "running",
            "docs": "/docs",
        }

    @app.get("/health", tags=["meta"])
    async def health():
        return {"status": "ok"}

    # ─── Exception handlers ─────────────────────────────────────
    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(_: Request, exc: RequestValidationError):
        # Compact, user-friendly validation errors
        errors = []
        for e in exc.errors():
            loc = ".".join(str(x) for x in e.get("loc", []) if x != "body")
            errors.append({"field": loc or "body", "message": e.get("msg", "")})
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "success": False,
                "message": "Validation error.",
                "errors": errors,
            },
        )

    @app.exception_handler(SQLAlchemyError)
    async def sqlalchemy_exception_handler(_: Request, exc: SQLAlchemyError):
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "success": False,
                "message": "A database error occurred.",
                "detail": str(exc) if settings.DEBUG else None,
            },
        )

    return app


app = create_app()
