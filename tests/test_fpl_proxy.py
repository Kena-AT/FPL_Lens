import secrets
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, patch

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.db.models import User
from fpl_lens.services.cache import set_cached_value
from fpl_lens.services.fpl_client import UpstreamUnavailableError
from fpl_lens.services.token import create_access_token


def test_fpl_proxy_authorization_and_ownership_404(client: TestClient, db_session: Session):
    """
    Spec & Implementation Plan requirement:
    Enforce that the caller's own team ID is the only one accepted.
    Requesting another user's team ID returns 404, covered by a test.
    """
    tag = uuid.uuid4().hex[:6]
    caller_team = secrets.randbelow(1_000_000) + 6_000_000
    other_team = caller_team + 100

    user = User(
        id=uuid.uuid4(),
        email=f"proxy_owner_{tag}@example.com",
        display_name="Proxy Owner",
        fpl_team_id=caller_team,
        status="active",
        email_verified_at=datetime.now(UTC),
    )
    db_session.add(user)
    db_session.commit()

    token = create_access_token(user)
    headers = {"Authorization": f"Bearer {token}"}

    # Requesting another team ID on all 4 proxy endpoints must return 404
    for endpoint in [
        f"/api/v1/fpl/entry/{other_team}",
        f"/api/v1/fpl/entry/{other_team}/squad?gw=1",
        f"/api/v1/fpl/entry/{other_team}/history",
        f"/api/v1/fpl/entry/{other_team}/transfers",
    ]:
        resp = client.get(endpoint, headers=headers)
        assert resp.status_code == 404
        assert resp.json()["error"]["code"] == "FPL_TEAM_NOT_FOUND"


def test_fpl_proxy_cache_and_stale_fallback(client: TestClient, db_session: Session):
    """
    Spec & Implementation Plan requirement:
    When FPL returns an error, the proxy returns cached data with a timestamp, or UPSTREAM_UNAVAILABLE.
    """
    tag = uuid.uuid4().hex[:6]
    team_id = secrets.randbelow(1_000_000) + 7_000_000

    user = User(
        id=uuid.uuid4(),
        email=f"cache_user_{tag}@example.com",
        display_name="Cache Tester",
        fpl_team_id=team_id,
        status="active",
        email_verified_at=datetime.now(UTC),
    )
    db_session.add(user)
    db_session.commit()

    token = create_access_token(user)
    headers = {"Authorization": f"Bearer {token}"}

    mock_entry = {
        "id": team_id,
        "name": "Winning Squad",
        "player_first_name": "Test",
        "player_last_name": "User",
    }

    # 1. Fresh fetch populates cache
    with patch(
        "fpl_lens.services.fpl_client.fpl_client.get_entry", new_callable=AsyncMock
    ) as mock_get:
        mock_get.return_value = mock_entry
        resp = client.get(f"/api/v1/fpl/entry/{team_id}", headers=headers)
        assert resp.status_code == 200
        assert resp.json()["name"] == "Winning Squad"
        assert resp.headers.get("x-data-status") == "FRESH"
        assert mock_get.call_count == 1

    # 2. Second request is served directly from cache (upstream not called)
    with patch(
        "fpl_lens.services.fpl_client.fpl_client.get_entry", new_callable=AsyncMock
    ) as mock_get2:
        resp2 = client.get(f"/api/v1/fpl/entry/{team_id}", headers=headers)
        assert resp2.status_code == 200
        assert resp2.json()["name"] == "Winning Squad"
        assert mock_get2.call_count == 0

    # 3. Upstream error with existing stale cache -> returns stale cached data with X-Data-Status: STALE
    # Artificially set an expired entry in DB
    cache_key = f"fpl:entry:{team_id}"
    set_cached_value(db_session, cache_key, mock_entry, ttl_seconds=-60)  # expired 60 seconds ago

    with patch(
        "fpl_lens.services.fpl_client.fpl_client.get_entry",
        side_effect=UpstreamUnavailableError("Connection refused by upstream"),
    ):
        resp_stale = client.get(f"/api/v1/fpl/entry/{team_id}", headers=headers)
        assert resp_stale.status_code == 200
        assert resp_stale.headers.get("x-data-status") == "STALE"
        assert "x-cached-at" in resp_stale.headers
        assert resp_stale.json()["name"] == "Winning Squad"

    # 4. Upstream error with NO cached data -> returns 503 UPSTREAM_UNAVAILABLE
    uncached_team = team_id + 50
    user.fpl_team_id = uncached_team
    db_session.commit()
    token_uncached = create_access_token(user)
    headers_uncached = {"Authorization": f"Bearer {token_uncached}"}

    with patch(
        "fpl_lens.services.fpl_client.fpl_client.get_entry",
        side_effect=UpstreamUnavailableError("Timeout from FPL"),
    ):
        resp_no_cache = client.get(f"/api/v1/fpl/entry/{uncached_team}", headers=headers_uncached)
        assert resp_no_cache.status_code == 503
        assert resp_no_cache.json()["error"]["code"] == "UPSTREAM_UNAVAILABLE"


def test_fpl_proxy_squad_history_transfers_success(client: TestClient, db_session: Session):
    """Verifies that squad, history, and transfers endpoints work for caller's own team."""
    tag = uuid.uuid4().hex[:6]
    team_id = secrets.randbelow(1_000_000) + 8_000_000

    user = User(
        id=uuid.uuid4(),
        email=f"proxy_full_{tag}@example.com",
        display_name="Full Proxy User",
        fpl_team_id=team_id,
        status="active",
        email_verified_at=datetime.now(UTC),
    )
    db_session.add(user)
    db_session.commit()

    token = create_access_token(user)
    headers = {"Authorization": f"Bearer {token}"}

    mock_picks = {
        "active_chip": None,
        "entry_history": {},
        "picks": [{"element": 1, "position": 1, "multiplier": 1}],
    }
    mock_history = {"current": [{"event": 1, "points": 65}], "past": [], "chips": []}
    mock_transfers = [{"element_in": 10, "element_out": 20, "event": 2}]

    with (
        patch(
            "fpl_lens.services.fpl_client.fpl_client.get_picks",
            new_callable=AsyncMock,
            return_value=mock_picks,
        ),
        patch(
            "fpl_lens.services.fpl_client.fpl_client.get_history",
            new_callable=AsyncMock,
            return_value=mock_history,
        ),
        patch(
            "fpl_lens.services.fpl_client.fpl_client.get_transfers",
            new_callable=AsyncMock,
            return_value=mock_transfers,
        ),
    ):
        resp_squad = client.get(f"/api/v1/fpl/entry/{team_id}/squad?gw=1", headers=headers)
        assert resp_squad.status_code == 200
        assert "picks" in resp_squad.json()

        resp_hist = client.get(f"/api/v1/fpl/entry/{team_id}/history", headers=headers)
        assert resp_hist.status_code == 200
        assert "current" in resp_hist.json()

        resp_trans = client.get(f"/api/v1/fpl/entry/{team_id}/transfers", headers=headers)
        assert resp_trans.status_code == 200
        assert len(resp_trans.json()) == 1
