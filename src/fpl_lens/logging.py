import contextvars
import json
import logging
import re
from datetime import UTC, datetime
from typing import Any

# Context variable to track request_id across async execution
request_id_ctx: contextvars.ContextVar[str | None] = contextvars.ContextVar(
    "request_id", default=None
)

# Compiled regex patterns for redaction
EMAIL_PATTERN = re.compile(
    r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"
)
SIX_DIGIT_CODE_PATTERN = re.compile(r"\b\d{6}\b")
JWT_TOKEN_PATTERN = re.compile(
    r"\bey[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*\b"
)
BEARER_PATTERN = re.compile(r"(?i)bearer\s+[A-Za-z0-9._~+/-]+", re.IGNORECASE)
LONG_SECRET_PATTERN = re.compile(r"\b[A-Za-z0-9_-]{32,}\b")
KEY_VALUE_SECRET_PATTERN = re.compile(
    r'(?i)(password|secret|client_secret|api_key|token|code)["\']?\s*[:=]\s*["\']?([^"\'\s,}{]+)',
)


def redact_text(text: str) -> str:
    """Redacts emails, codes, tokens, passwords, and secrets from a string."""
    if not isinstance(text, str):
        return text

    # Redact key-value secrets first
    text = KEY_VALUE_SECRET_PATTERN.sub(r'\1: [REDACTED]', text)
    # Redact Authorization header values
    text = BEARER_PATTERN.sub('Bearer [REDACTED]', text)
    # Redact JWTs
    text = JWT_TOKEN_PATTERN.sub('[REDACTED_TOKEN]', text)
    # Redact emails
    text = EMAIL_PATTERN.sub('[REDACTED_EMAIL]', text)
    # Redact 6-digit verification codes
    text = SIX_DIGIT_CODE_PATTERN.sub('[REDACTED_CODE]', text)
    # Redact long tokens
    text = LONG_SECRET_PATTERN.sub('[REDACTED_TOKEN]', text)

    return text


def redact_object(obj: Any) -> Any:
    """Recursively redacts dictionary, list, or primitive values."""
    if isinstance(obj, str):
        return redact_text(obj)
    if isinstance(obj, dict):
        redacted = {}
        for k, v in obj.items():
            if any(s in k.lower() for s in ["password", "secret", "token", "code", "key"]):
                redacted[k] = "[REDACTED]"
            elif "email" in k.lower() and isinstance(v, str):
                redacted[k] = "[REDACTED_EMAIL]"
            elif "name" in k.lower() and isinstance(v, str) and k.lower() not in ["job_name", "model_version", "short_name"]:
                redacted[k] = "[REDACTED_NAME]"
            else:
                redacted[k] = redact_object(v)
        return redacted
    if isinstance(obj, list):
        return [redact_object(i) for i in obj]
    return obj


class RedactionFilter(logging.Filter):
    """Logging filter that ensures no emails, tokens, codes, or secrets reach log sinks."""

    def filter(self, record: logging.LogRecord) -> bool:
        try:
            formatted_msg = record.getMessage()
        except (TypeError, ValueError, KeyError, IndexError):
            formatted_msg = str(record.msg)

        record.msg = redact_text(formatted_msg)
        record.args = ()
        return True


class JsonFormatter(logging.Formatter):
    """Outputs structured JSON log records with timestamps and request IDs."""

    def format(self, record: logging.LogRecord) -> str:
        log_data: dict[str, Any] = {
            "timestamp": datetime.now(UTC).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "request_id": request_id_ctx.get(),
        }

        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_data)


def setup_logging(level: str = "INFO") -> logging.Logger:
    """Configures application-wide structured JSON logging with redaction."""
    logger = logging.getLogger("fpl_lens")
    logger.setLevel(getattr(logging, level.upper(), logging.INFO))

    # Remove existing handlers to avoid duplicates
    for h in list(logger.handlers):
        logger.removeHandler(h)

    handler = logging.StreamHandler()
    handler.setFormatter(JsonFormatter())
    handler.addFilter(RedactionFilter())
    logger.addHandler(handler)
    logger.propagate = False

    return logger


logger = setup_logging()
