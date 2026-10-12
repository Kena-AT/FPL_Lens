import uuid

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from src.fpl_lens.logging import logger, request_id_ctx


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
            logger.info("Request completed: %s %s - status %d", request.method, request.url.path, response.status_code)
            return response
        finally:
            request_id_ctx.reset(token)
