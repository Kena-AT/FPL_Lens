import threading
from collections import defaultdict
from datetime import UTC, datetime, timedelta

from fastapi import status

from fpl_lens.api.errors import AppError


class RateLimiter:
    """
    Thread-safe in-memory sliding window rate limiter.
    Maintains request timestamps per (scope, identifier).
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._records: dict[tuple[str, str], list[datetime]] = defaultdict(list)

    def _cleanup_window(
        self, scope: str, identifier: str, window_seconds: int, now: datetime
    ) -> list[datetime]:
        cutoff = now - timedelta(seconds=window_seconds)
        key = (scope, identifier)
        valid = [ts for ts in self._records[key] if ts > cutoff]
        self._records[key] = valid
        return valid

    def check(
        self,
        scope: str,
        identifier: str,
        max_requests: int,
        window_seconds: int,
        record: bool = True,
    ) -> None:
        """
        Validates whether a request is within the allowable limit.
        If record is True, appends the current timestamp to the history.
        Raises AppError(status_code=429, code='RATE_LIMITED') when the limit is reached or exceeded.
        """
        now = datetime.now(UTC)
        with self._lock:
            history = self._cleanup_window(scope, identifier, window_seconds, now)
            if len(history) >= max_requests:
                # Compute seconds until oldest recorded attempt in window expires
                oldest = history[0]
                retry_after = max(1, int((oldest + timedelta(seconds=window_seconds) - now).total_seconds()))
                raise AppError(
                    code="RATE_LIMITED",
                    message=f"Rate limit exceeded for {scope}. Please wait {retry_after}s before retrying.",
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                )
            if record:
                self._records[(scope, identifier)].append(now)

    def record_hit(self, scope: str, identifier: str) -> None:
        """Explicitly records an event (e.g. failed login attempt)."""
        now = datetime.now(UTC)
        with self._lock:
            self._records[(scope, identifier)].append(now)

    def reset(self) -> None:
        """Resets all tracked rate limit records. Intended for test suites."""
        with self._lock:
            self._records.clear()


rate_limiter = RateLimiter()
