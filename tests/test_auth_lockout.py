import secrets
import uuid
from unittest.mock import patch

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.db.models import User
from fpl_lens.services.hasher import hash_password


def test_ten_failed_logins_lock_account_for_15_minutes(client: TestClient, db_session: Session):
    tag = uuid.uuid4().hex[:6]
    team_id = secrets.randbelow(1_000_000) + 7_000_000
    password = "CorrectPassword123!"
    user = User(
        id=uuid.uuid4(),
        email=f"lockout_user_{tag}@example.com",
        password_hash=hash_password(password),
        display_name="Lockout Tester",
        fpl_team_id=team_id,
        status="active",
        failed_login_count=0,
    )
    db_session.add(user)
    db_session.commit()

    with patch("fpl_lens.services.mailer._send_smtp_message"):
        # First 9 failed attempts return 401 INVALID_CREDENTIALS
        for _ in range(1, 10):
            resp = client.post(
                "/api/v1/auth/login",
                json={"email": user.email, "password": "WrongPassword123!"},
            )
            assert resp.status_code == 401
            assert resp.json()["error"]["code"] == "INVALID_CREDENTIALS"

        # 10th failed attempt locks the account and returns 403 ACCOUNT_LOCKED
        resp_10 = client.post(
            "/api/v1/auth/login",
            json={"email": user.email, "password": "WrongPassword123!"},
        )
        assert resp_10.status_code == 403
        assert resp_10.json()["error"]["code"] == "ACCOUNT_LOCKED"

        # 11th attempt (even with the CORRECT password) is locked out!
        resp_11 = client.post(
            "/api/v1/auth/login",
            json={"email": user.email, "password": password},
        )
        assert resp_11.status_code == 403
        assert resp_11.json()["error"]["code"] == "ACCOUNT_LOCKED"
