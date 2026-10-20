from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.middleware.gzip import GZipMiddleware

from fpl_lens.api.errors import (
    AppError,
    app_error_handler,
    http_exception_handler,
    unhandled_exception_handler,
    validation_exception_handler,
)
from fpl_lens.api.middleware import RequestIdMiddleware
from fpl_lens.api.routes.auth import router as auth_router
from fpl_lens.api.routes.devices import router as devices_router
from fpl_lens.api.routes.fpl_proxy import router as fpl_proxy_router
from fpl_lens.api.routes.health import router as health_router
from fpl_lens.api.routes.internal_jobs import router as internal_jobs_router
from fpl_lens.api.routes.me import router as me_router
from fpl_lens.api.routes.projections import router as projections_router
from fpl_lens.config import settings


def create_app() -> FastAPI:
    """FastAPI application factory."""
    app = FastAPI(
        title="FPL Lens API",
        version="0.1.0",
        docs_url="/docs",
        redoc_url=None,
    )

    # Register middleware
    if settings.is_dev:
        from fastapi.middleware.cors import CORSMiddleware

        app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

    app.add_middleware(RequestIdMiddleware)
    # Enable GZip compression per Backend Design §7.2
    app.add_middleware(GZipMiddleware, minimum_size=500)

    # Register exception handlers
    app.add_exception_handler(AppError, app_error_handler)
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(Exception, unhandled_exception_handler)

    # Register routers
    app.include_router(health_router)
    app.include_router(health_router, prefix="/api/v1")
    app.include_router(auth_router, prefix="/api/v1")
    app.include_router(me_router, prefix="/api/v1")
    app.include_router(devices_router, prefix="/api/v1")
    app.include_router(fpl_proxy_router, prefix="/api/v1")
    app.include_router(projections_router, prefix="/api/v1")
    app.include_router(internal_jobs_router)
    app.include_router(internal_jobs_router, prefix="/api/v1")

    return app


app = create_app()
