from typing import Any, Dict, Optional
from fastapi import Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException
from src.fpl_lens.logging import logger, request_id_ctx


class AppError(Exception):
    """Base application exception with standardized code and status code."""

    def __init__(
        self,
        code: str,
        message: str,
        status_code: int = status.HTTP_400_BAD_REQUEST,
        details: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code
        self.details = details or {}


def format_error_response(code: str, message: str, request_id: Optional[str]) -> Dict[str, Any]:
    return {
        "error": {
            "code": code,
            "message": message,
            "request_id": request_id or "",
        }
    }


async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    request_id = getattr(request.state, "request_id", None) or request_id_ctx.get()
    logger.warning("Application error: code=%s, message=%s", exc.code, exc.message)
    return JSONResponse(
        status_code=exc.status_code,
        content=format_error_response(exc.code, exc.message, request_id),
    )


async def http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    request_id = getattr(request.state, "request_id", None) or request_id_ctx.get()
    code_map = {
        401: "UNAUTHENTICATED",
        403: "FORBIDDEN",
        404: "NOT_FOUND",
        409: "CONFLICT",
        422: "VALIDATION_FAILED",
        429: "RATE_LIMITED",
        503: "SERVICE_UNAVAILABLE",
    }
    code = code_map.get(exc.status_code, "ERROR")
    logger.warning("HTTP %d error: %s", exc.status_code, exc.detail)
    return JSONResponse(
        status_code=exc.status_code,
        content=format_error_response(code, str(exc.detail), request_id),
    )


async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    request_id = getattr(request.state, "request_id", None) or request_id_ctx.get()
    logger.warning("Validation error on request: %s", exc.errors())
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=format_error_response("VALIDATION_FAILED", "Request validation failed", request_id),
    )


async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    request_id = getattr(request.state, "request_id", None) or request_id_ctx.get()
    logger.error("Unhandled exception: %s", exc, exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=format_error_response("INTERNAL_SERVER_ERROR", "An unexpected error occurred", request_id),
    )
