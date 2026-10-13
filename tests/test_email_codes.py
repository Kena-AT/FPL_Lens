import secrets
import uuid
from datetime import UTC, datetime, timedelta
from unittest.mock import patch

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.db.models import EmailCode, User
from fpl_lens.services.hasher import hash_password
from fpl_lens.services.token import (
    create_access_token,
    create_and_store_email_code,
    hash_token,
)


def test_code_accepted_once_and_expiry(client: TestClient, db_session: Session):
    tag = uuid.uuid4().hex[:6]
    team_id = secrets.randbelow(1_000_000) + 1_000_000
    user = User(
        id=uuid.uuid4(),
        email=f"code_user_{tag}@example.com",
        password_hash=hash_password("ValidPassword123!"),
        display_name="Code Tester",
        fpl_team_id=team_id,
        status="unverified",
    )
    db_session.add(user)
    db_session.commit()

    token = create_access_token(user)
    headers = {"Authorization": f"Bearer {token}"}

    # Generate code
    raw_code = create_and_store_email_code(db_session, user.id, "verify_email", 10)

    # First attempt: succeeds
    resp1 = client.post("/api/v1/auth/verify-email", json={"code": raw_code}, headers=headers)
    assert resp1.status_code == 200
    data1 = resp1.json()
    assert "access_token" in data1
    assert "refresh_token" in data1

    # Second attempt with same code: fails (code already used)
    user.status = "unverified"
    user.email_verified_at = None
    db_session.commit()

    resp2 = client.post("/api/v1/auth/verify-email", json={"code": raw_code}, headers=headers)
    assert resp2.status_code == 400
    assert resp2.json()["error"]["code"] == "INVALID_VERIFICATION_CODE"

    # Test expired code (> 10 minutes)
    expired_code = "123456"
    expired_entry = EmailCode(
        id=uuid.uuid4(),
        user_id=user.id,
        purpose="verify_email",
        code_hash=hash_token(expired_code),
        attempts=0,
        expires_at=datetime.now(UTC) - timedelta(minutes=1),
        used_at=None,
    )
    db_session.add(expired_entry)
    db_session.commit()

    resp_expired = client.post("/api/v1/auth/verify-email", json={"code": expired_code}, headers=headers)
    assert resp_expired.status_code == 400
    assert resp_expired.json()["error"]["code"] == "INVALID_VERIFICATION_CODE"


def test_code_invalidated_after_five_wrong_attempts(client: TestClient, db_session: Session):
    tag = uuid.uuid4().hex[:6]
    team_id = secrets.randbelow(1_000_000) + 2_000_000
    user = User(
        id=uuid.uuid4(),
        email=f"attempt_user_{tag}@example.com",
        password_hash=hash_password("ValidPassword123!"),
        display_name="Attempt Tester",
        fpl_team_id=team_id,
        status="unverified",
    )
    db_session.add(user)
    db_session.commit()

    token = create_access_token(user)
    headers = {"Authorization": f"Bearer {token}"}

    correct_code = create_and_store_email_code(db_session, user.id, "verify_email", 10)

    # Submit 5 wrong codes
    for _ in range(5):
        resp_wrong = client.post("/api/v1/auth/verify-email", json={"code": "000000"}, headers=headers)
        assert resp_wrong.status_code == 400

    # 6th attempt: submit the CORRECT code -> should be rejected because attempts >= 5
    resp_correct = client.post("/api/v1/auth/verify-email", json={"code": correct_code}, headers=headers)
    assert resp_correct.status_code == 400
    assert resp_correct.json()["error"]["code"] == "INVALID_VERIFICATION_CODE"


def test_resend_rate_limits(client: TestClient, db_session: Session):
    tag = uuid.uuid4().hex[:6]
    team_id = secrets.randbelow(1_000_000) + 2_500_000
    user = User(
        id=uuid.uuid4(),
        email=f"resend_user_{tag}@example.com",
        password_hash=hash_password("ValidPassword123!"),
        display_name="Resend Tester",
        fpl_team_id=team_id,
        status="unverified",
    )
    db_session.add(user)
    db_session.commit()

    token = create_access_token(user)
    headers = {"Authorization": f"Bearer {token}"}

    with patch("fpl_lens.services.mailer._send_smtp_message"):
        # First resend succeeds
        r1 = client.post("/api/v1/auth/verify-email/resend", headers=headers)
        assert r1.status_code == 200

        # Immediate second resend fails with 429 RATE_LIMITED (1 per minute limit)
        r2 = client.post("/api/v1/auth/verify-email/resend", headers=headers)
        assert r2.status_code == 429
        assert r2.json()["error"]["code"] == "RATE_LIMITED"
