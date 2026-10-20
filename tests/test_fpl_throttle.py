import pytest

from fpl_lens.services.fpl_client import FPLClient, FPLRateLimiter, UpstreamThrottledError


class MockClock:
    """Controllable test clock for verifying rate limiting and throttling deterministically."""

    def __init__(self, start_time: float = 1000.0):
        self.current_time = start_time
        self.slept_intervals: list[float] = []

    def time(self) -> float:
        return self.current_time

    async def sleep(self, duration: float) -> None:
        self.slept_intervals.append(duration)
        self.current_time += duration


@pytest.mark.asyncio
async def test_fpl_rate_limiter_with_test_clock():
    """
    Spec & Implementation Plan requirement:
    The proxy never sends a request faster than the configured throttle. Verified with a test clock.
    Configured throttle: 3 requests per second -> min 1/3s (0.3333s) between requests.
    """
    mock_clock = MockClock(100.0)
    limiter = FPLRateLimiter(rps=3.0, clock=mock_clock.time, sleep_fn=mock_clock.sleep)

    # First request: acquired immediately without sleeping
    slept1 = await limiter.acquire()
    assert slept1 == 0.0
    assert len(mock_clock.slept_intervals) == 0

    # Immediate second request: must sleep ~0.3333s
    slept2 = await limiter.acquire()
    assert pytest.approx(slept2, abs=1e-3) == 1.0 / 3.0
    assert len(mock_clock.slept_intervals) == 1
    assert pytest.approx(mock_clock.slept_intervals[0], abs=1e-3) == 1.0 / 3.0

    # Immediate third request: must sleep ~0.3333s
    slept3 = await limiter.acquire()
    assert pytest.approx(slept3, abs=1e-3) == 1.0 / 3.0
    assert len(mock_clock.slept_intervals) == 2

    # Fourth request after advancing clock by 1.0s: no sleep needed
    mock_clock.current_time += 1.0
    slept4 = await limiter.acquire()
    assert slept4 == 0.0


@pytest.mark.asyncio
async def test_fpl_bootstrap_throttle_with_test_clock():
    """
    Spec & Implementation Plan requirement:
    One bootstrap request per 10 minutes (600s).
    """
    mock_clock = MockClock(5000.0)
    client = FPLClient(clock=mock_clock.time)
    client.bootstrap_throttle_seconds = 600

    # Mock _request so no actual network call is made
    called_count = 0

    async def fake_request(method, endpoint, **kwargs):
        nonlocal called_count
        called_count += 1
        return type(
            "MockResponse", (), {"status_code": 200, "json": lambda *args, **kwargs: {"teams": []}}
        )()

    client._request = fake_request

    # 1. First call: succeeds
    res1 = await client.get_bootstrap_static(enforce_throttle=True)
    assert "teams" in res1
    assert called_count == 1

    # 2. Second call immediately (0s elapsed): raises UpstreamThrottledError
    with pytest.raises(UpstreamThrottledError, match="Bootstrap requested too soon"):
        await client.get_bootstrap_static(enforce_throttle=True)
    assert called_count == 1

    # 3. Third call after 300s (5 min, still < 600s): still raises
    mock_clock.current_time += 300.0
    with pytest.raises(UpstreamThrottledError, match="Bootstrap requested too soon"):
        await client.get_bootstrap_static(enforce_throttle=True)
    assert called_count == 1

    # 4. Fourth call after 601s total (10m+1s): succeeds
    mock_clock.current_time += 301.0
    res4 = await client.get_bootstrap_static(enforce_throttle=True)
    assert "teams" in res4
    assert called_count == 2
