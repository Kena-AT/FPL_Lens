from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from fpl_lens.api.errors import (
    AppError,
    app_error_handler,
    http_exception_handler,
    unhandled_exception_handler,
    validation_exception_handler,
)
from fpl_lens.api.middleware import RequestIdMiddleware
from fpl_lens.api.routes.health import router as health_router


def create_app() -> FastAPI:
    """FastAPI application factory."""
    app = FastAPI(
        title="FPL Lens API",
        version="0.1.0",
        docs_url="/docs",
        redoc_url=None,
    )

    # Register middleware
    app.add_middleware(RequestIdMiddleware)

    # Register exception handlers
    app.add_exception_handler(AppError, app_error_handler)
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(Exception, unhandled_exception_handler)

    # Register routers
    app.include_router(health_router)

    return app


app = create_app()
