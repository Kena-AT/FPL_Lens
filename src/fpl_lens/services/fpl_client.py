import asyncio
import time
from collections.abc import Callable
from typing import Any

import httpx

from fpl_lens.config import settings
from fpl_lens.logging import logger


class UpstreamUnavailableError(Exception):
    """Raised when FPL upstream cannot be reached or returns persistent 5xx."""


class UpstreamThrottledError(Exception):
    """Raised when an action violates upstream budget (e.g. bootstrap within 10 minutes)."""


class FPLRateLimiter:
    """Enforces requests per second rate limit with pluggable clock for testing."""

    def __init__(
        self,
        rps: float = 3.0,
        clock: Callable[[], float] | None = None,
        sleep_fn: Callable[[float], Any] | None = None,
    ):
        self.rps = rps
        self.min_interval = (1.0 / rps) if rps > 0 else 0.0
        self.last_request_time = 0.0
        self.clock = clock or time.monotonic
        self.sleep_fn = sleep_fn or asyncio.sleep
        self._lock = asyncio.Lock()

    async def acquire(self) -> float:
        """Waits if needed to satisfy rate limit. Returns elapsed time slept."""
        async with self._lock:
            now = self.clock()
            elapsed = now - self.last_request_time
            slept = 0.0
            if elapsed < self.min_interval and self.last_request_time > 0.0:
                wait_time = self.min_interval - elapsed
                await self.sleep_fn(wait_time)
                slept = wait_time
                self.last_request_time = self.clock()
            else:
                self.last_request_time = now
            return slept


class FPLClient:
    """
    Shared asynchronous HTTP client for the official FPL API.
    Enforces identifiable User-Agent, global throttle (3 req/sec),
    bootstrap 10-minute rate limit, and exponential backoff retry.
    """

    def __init__(
        self,
        base_url: str | None = None,
        user_agent: str | None = None,
        timeout: float = 10.0,
        rate_limiter: FPLRateLimiter | None = None,
        clock: Callable[[], float] | None = None,
    ):
        self.base_url = (base_url or settings.FPL_BASE_URL).rstrip("/")
        self.user_agent = user_agent or settings.FPL_USER_AGENT
        self.timeout = timeout
        self.clock = clock or time.monotonic
        self.rate_limiter = rate_limiter or FPLRateLimiter(
            rps=settings.FPL_GLOBAL_THROTTLE_RPS,
            clock=self.clock,
        )
        self.bootstrap_throttle_seconds = settings.FPL_BOOTSTRAP_THROTTLE_SECONDS
        self.last_bootstrap_time: float | None = None
        self._client: httpx.AsyncClient | None = None
        self._lock = asyncio.Lock()

    def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(timeout=self.timeout)
        return self._client

    async def close(self) -> None:
        if self._client and not self._client.is_closed:
            await self._client.aclose()

    async def _request(self, method: str, endpoint: str, **kwargs) -> httpx.Response:
        await self.rate_limiter.acquire()

        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        headers = kwargs.pop("headers", {}) or {}
        headers["User-Agent"] = self.user_agent

        client = self._get_client()
        retries = 0
        backoff = 0.5

        while True:
            try:
                response = await client.request(method, url, headers=headers, **kwargs)

                # Retry on 5xx up to 2 times
                if response.status_code >= 500 and retries < 2:
                    retries += 1
                    logger.warning(
                        "FPL returned %d on %s. Retry %d/2 in %.1fs.",
                        response.status_code,
                        endpoint,
                        retries,
                        backoff,
                    )
                    await asyncio.sleep(backoff)
                    backoff *= 2
                    continue

                # 403 or blocked check per AGENTS.md §7.2
                if response.status_code == 403:
                    logger.error("FPL returned 403 Forbidden on %s. Upstream may be blocking User-Agent.", endpoint)

                return response

            except httpx.TransportError as exc:
                if retries < 2:
                    retries += 1
                    logger.warning(
                        "FPL network transport error (%s) on %s. Retry %d/2 in %.1fs.",
                        type(exc).__name__,
                        endpoint,
                        retries,
                        backoff,
                    )
                    await asyncio.sleep(backoff)
                    backoff *= 2
                    continue
                logger.error("FPL upstream connection failed after retries on %s: %s", endpoint, exc)
                raise UpstreamUnavailableError(f"FPL request to {endpoint} failed: {exc}") from exc

    async def get_entry(self, team_id: int) -> dict[str, Any] | None:
        """Fetches /api/entry/{team_id}/. Returns dict if found, None if 404."""
        resp = await self._request("GET", f"/api/entry/{team_id}/")
        if resp.status_code == 404:
            return None
        if resp.status_code >= 400:
            raise UpstreamUnavailableError(f"FPL entry returned status {resp.status_code}")
        return resp.json()

    async def get_picks(self, team_id: int, gameweek: int) -> dict[str, Any] | None:
        """Fetches /api/entry/{team_id}/event/{gw}/picks/."""
        resp = await self._request("GET", f"/api/entry/{team_id}/event/{gameweek}/picks/")
        if resp.status_code == 404:
            return None
        if resp.status_code >= 400:
            raise UpstreamUnavailableError(f"FPL picks returned status {resp.status_code}")
        return resp.json()

    async def get_history(self, team_id: int) -> dict[str, Any] | None:
        """Fetches /api/entry/{team_id}/history/."""
        resp = await self._request("GET", f"/api/entry/{team_id}/history/")
        if resp.status_code == 404:
            return None
        if resp.status_code >= 400:
            raise UpstreamUnavailableError(f"FPL history returned status {resp.status_code}")
        return resp.json()

    async def get_transfers(self, team_id: int) -> list[dict[str, Any]] | None:
        """Fetches /api/entry/{team_id}/transfers/."""
        resp = await self._request("GET", f"/api/entry/{team_id}/transfers/")
        if resp.status_code == 404:
            return None
        if resp.status_code >= 400:
            raise UpstreamUnavailableError(f"FPL transfers returned status {resp.status_code}")
        return resp.json()

    async def get_bootstrap_static(self, enforce_throttle: bool = True) -> dict[str, Any]:
        """
        Fetches /api/bootstrap-static/.
        Enforces 10-minute throttle unless enforce_throttle=False.
        """
        async with self._lock:
            now = self.clock()
            if enforce_throttle and self.last_bootstrap_time is not None:
                elapsed = now - self.last_bootstrap_time
                if elapsed < self.bootstrap_throttle_seconds:
                    raise UpstreamThrottledError(
                        f"Bootstrap requested too soon ({elapsed:.1f}s < {self.bootstrap_throttle_seconds}s)"
                    )
            self.last_bootstrap_time = now

        resp = await self._request("GET", "/api/bootstrap-static/")
        if resp.status_code >= 400:
            raise UpstreamUnavailableError(f"FPL bootstrap returned status {resp.status_code}")
        return resp.json()

    async def get_fixtures(self) -> list[dict[str, Any]]:
        """Fetches /api/fixtures/."""
        resp = await self._request("GET", "/api/fixtures/")
        if resp.status_code >= 400:
            raise UpstreamUnavailableError(f"FPL fixtures returned status {resp.status_code}")
        return resp.json()

    async def get_element_summary(self, player_fpl_id: int) -> dict[str, Any] | None:
        """Fetches /api/element-summary/{player_fpl_id}/."""
        resp = await self._request("GET", f"/api/element-summary/{player_fpl_id}/")
        if resp.status_code == 404:
            return None
        if resp.status_code >= 400:
            raise UpstreamUnavailableError(f"FPL element-summary returned status {resp.status_code}")
        return resp.json()


# Singleton shared client
fpl_client = FPLClient()
