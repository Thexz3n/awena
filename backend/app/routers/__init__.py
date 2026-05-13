from app.routers.auth import router as auth_router
from app.routers.history import router as history_router
from app.routers.users import router as users_router

__all__ = ["auth_router", "users_router", "history_router"]
