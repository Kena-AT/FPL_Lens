import uuid

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from fpl_lens.logging import logger, request_id_ctx


class RequestIdMiddleware(BaseHTTPMiddleware):
    """
    Middleware that assigns a UUID request ID to every incoming HTTP request,
    propagates it to the logging context, and attaches it as an X-Request-ID response header.
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        incoming_id = request.headers.get("X-Request-ID")
        request_id = incoming_id if incoming_id else str(uuid.uuid4())

        # Set in contextvar and request state
        token = request_id_ctx.set(request_id)
        request.state.request_id = request_id

        logger.info("Request started: %s %s", request.method, request.url.path)
        try:
            response = await call_next(request)
            response.headers["X-Request-ID"] = request_id
            logger.info(
                "Request completed: %s %s - status %d",
                request.method,
                request.url.path,
                response.status_code,
            )
            return response
        finally:
            request_id_ctx.reset(token)


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """
    Middleware enforcing baseline security headers across all responses (Backend Design §12.1)
    and ensuring Cache-Control: no-store on all user account endpoints.
    """

    ACCOUNT_PATHS = (
        "/api/v1/auth",
        "/api/v1/me",
        "/api/v1/devices",
        "/api/v1/squads",
    )

    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)

        # Baseline security headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

        # Cache-Control: no-store on account responses
        path = request.url.path
        if any(path.startswith(prefix) for prefix in self.ACCOUNT_PATHS):
            response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, private"

        return response

