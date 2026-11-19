import secrets
import uuid
from datetime import UTC, datetime, timedelta
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.config import settings
from fpl_lens.db.models import EmailCode, User
from fpl_lens.services.hasher import hash_password
from fpl_lens.services.rate_limiter import rate_limiter
from fpl_lens.services.token import create_access_token


@pytest.fixture(autouse=True)
def reset_rate_limiter():
    rate_limiter.reset()
    yield
    rate_limiter.reset()


def test_registration_per_ip_rate_limit(client: TestClient):
    """Exceeding 10 registrations per hour from the same IP returns 429."""
    ip = "192.168.1.10"
    headers = {"X-Forwarded-For": ip}

    # Simulate 10 successful/prior registration attempts
    for _i in range(settings.RATE_LIMIT_REGISTRATION_IP_REQUESTS):
        rate_limiter.record_hit("registration_ip", ip)

    # 11th registration attempt must fail with 429
    resp = client.post(
        "/api/v1/auth/register",
        json={
            "email": "test_rl_reg@example.com",
            "password": "ValidPassword123!",
            "display_name": "RL Reg",
            "fpl_team_id": 9999999,
        },
        headers=headers,
    )
    assert resp.status_code == 429
    assert resp.json()["error"]["code"] == "RATE_LIMITED"


def test_login_per_ip_rate_limit(client: TestClient):
    """Exceeding 100 login attempts per 15 minutes from the same IP returns 429."""
    ip = "192.168.1.20"
    headers = {"X-Forwarded-For": ip}

    for _ in range(settings.RATE_LIMIT_LOGIN_IP_REQUESTS):
        rate_limiter.record_hit("login_ip", ip)

    resp = client.post(
        "/api/v1/auth/login",
        json={"email": "nobody@example.com", "password": "WrongPassword123!"},
        headers=headers,
    )
    assert resp.status_code == 429
    assert resp.json()["error"]["code"] == "RATE_LIMITED"


def test_team_id_lookup_per_ip_rate_limit(client: TestClient, db_session: Session):
    """Exceeding 30 team lookups per hour from the same IP returns 429."""
    ip = "192.168.1.30"
    headers = {"X-Forwarded-For": ip}

    team_id = secrets.randbelow(1_000_000) + 8_000_000
    user = User(
        id=uuid.uuid4(),
        email=f"team_lookup_{uuid.uuid4().hex[:6]}@example.com",
        password_hash=hash_password("Pass123!"),
        display_name="Lookup Tester",
        fpl_team_id=team_id,
        status="active",
        email_verified_at=datetime.now(UTC),
    )
    db_session.add(user)
    db_session.commit()

    token = create_access_token(user)
    headers["Authorization"] = f"Bearer {token}"

    for _ in range(settings.RATE_LIMIT_TEAM_LOOKUP_IP_REQUESTS):
        rate_limiter.record_hit("team_lookup_ip", ip)

    resp = client.get(f"/api/v1/fpl/entry/{team_id}", headers=headers)
    assert resp.status_code == 429
    assert resp.json()["error"]["code"] == "RATE_LIMITED"


def test_general_per_user_rate_limit(client: TestClient, db_session: Session):
    """Exceeding 300 requests per minute by a single user returns 429."""
    team_id = secrets.randbelow(1_000_000) + 8_100_000
    user = User(
        id=uuid.uuid4(),
        email=f"general_user_{uuid.uuid4().hex[:6]}@example.com",
        password_hash=hash_password("Pass123!"),
        display_name="General User",
        fpl_team_id=team_id,
        status="active",
        email_verified_at=datetime.now(UTC),
    )
    db_session.add(user)
    db_session.commit()

    token = create_access_token(user)
    headers = {"Authorization": f"Bearer {token}"}

    # Simulate 300 requests
    for _ in range(settings.RATE_LIMIT_GENERAL_USER_REQUESTS):
        rate_limiter.record_hit("general_user", str(user.id))

    # 301st request should be blocked by get_current_user
    resp = client.get("/api/v1/me", headers=headers)
    assert resp.status_code == 429
    assert resp.json()["error"]["code"] == "RATE_LIMITED"


def test_verification_code_per_minute_rate_limit(client: TestClient, db_session: Session):
    """Requesting more than 1 code per minute returns 429."""
    team_id = secrets.randbelow(1_000_000) + 8_200_000
    user = User(
        id=uuid.uuid4(),
        email=f"unverified_{uuid.uuid4().hex[:6]}@example.com",
        password_hash=hash_password("Pass123!"),
        display_name="Unverified User",
        fpl_team_id=team_id,
        status="unverified",
    )
    db_session.add(user)
    db_session.commit()

    token = create_access_token(user)
    headers = {"Authorization": f"Bearer {token}"}

    with patch("fpl_lens.services.mailer._send_smtp_message"):
        # First request succeeds
        resp1 = client.post("/api/v1/auth/verify-email/resend", headers=headers)
        assert resp1.status_code == 200

        # Immediate second request is blocked by 1-per-minute rule
        resp2 = client.post("/api/v1/auth/verify-email/resend", headers=headers)
        assert resp2.status_code == 429
        assert resp2.json()["error"]["code"] == "RATE_LIMITED"


def test_verification_code_per_hour_rate_limit(client: TestClient, db_session: Session):
    """Exceeding 5 codes per hour returns 429."""
    team_id = secrets.randbelow(1_000_000) + 8_300_000
    user = User(
        id=uuid.uuid4(),
        email=f"unverified_hour_{uuid.uuid4().hex[:6]}@example.com",
        password_hash=hash_password("Pass123!"),
        display_name="Unverified Hour User",
        fpl_team_id=team_id,
        status="unverified",
    )
    db_session.add(user)
    db_session.commit()

    # Pre-populate 5 email codes within the past 30 minutes
    now = datetime.now(UTC)
    for i in range(5):
        code = EmailCode(
            id=uuid.uuid4(),
            user_id=user.id,
            code_hash=f"fakehash{i}".encode(),
            purpose="verify_email",
            expires_at=now + timedelta(minutes=10),
            created_at=now - timedelta(minutes=10 + i),
        )
        db_session.add(code)
    db_session.commit()

    token = create_access_token(user)
    headers = {"Authorization": f"Bearer {token}"}

    with patch("fpl_lens.services.mailer._send_smtp_message"):
        resp = client.post("/api/v1/auth/verify-email/resend", headers=headers)
        assert resp.status_code == 429
        assert resp.json()["error"]["code"] == "RATE_LIMITED"


def test_login_per_account_rate_limit_scope():
    """Verifies login per account scope exceeds and raises 429."""
    scope = "login_per_account"
    identifier = "victim@example.com"

    for _ in range(settings.RATE_LIMIT_LOGIN_ACCOUNT_FAILURES):
        rate_limiter.record_hit(scope, identifier)

    with pytest.raises(Exception) as exc_info:
        rate_limiter.check(
            scope=scope,
            identifier=identifier,
            max_requests=settings.RATE_LIMIT_LOGIN_ACCOUNT_FAILURES,
            window_seconds=settings.RATE_LIMIT_LOGIN_ACCOUNT_WINDOW_SECONDS,
        )
    assert exc_info.value.status_code == 429
    assert exc_info.value.code == "RATE_LIMITED"


def test_security_headers_and_cache_control(client: TestClient):
    """Verifies security headers and Cache-Control: no-store on account endpoints."""
    # Test public projection route has security headers but allows caching
    resp_pub = client.get("/api/v1/gameweeks/current")
    assert resp_pub.headers["X-Content-Type-Options"] == "nosniff"
    assert resp_pub.headers["X-Frame-Options"] == "DENY"
    assert "Strict-Transport-Security" in resp_pub.headers

    # Test account endpoint has Cache-Control: no-store
    resp_auth = client.post(
        "/api/v1/auth/login",
        json={"email": "nobody@example.com", "password": "WrongPassword123!"},
    )
    assert resp_auth.headers["X-Content-Type-Options"] == "nosniff"
    assert resp_auth.headers["X-Frame-Options"] == "DENY"
    assert "Strict-Transport-Security" in resp_auth.headers
    assert "no-store" in resp_auth.headers.get("Cache-Control", "")
