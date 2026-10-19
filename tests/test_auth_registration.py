import secrets
import uuid
from unittest.mock import AsyncMock, patch

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.db.models import User
from fpl_lens.services.token import create_access_token


def test_registration_and_unverified_restrictions(client: TestClient, db_session: Session):
    tag = uuid.uuid4().hex[:6]
    base_team = secrets.randbelow(1_000_000) + 5_000_000
    email = f"unverified_{tag}@example.com"

    # 1. Register a new user
    reg_payload = {
        "email": email,
        "password": "ValidPassword1234!",
        "display_name": "Unverified Tester",
        "fpl_team_id": base_team,
    }

    with (
        patch("fpl_lens.services.mailer._send_smtp_message"),
        patch(
            "fpl_lens.api.routes.auth.check_fpl_team_exists",
            new_callable=AsyncMock,
            return_value=True,
        ),
    ):
        resp = client.post("/api/v1/auth/register", json=reg_payload)
        assert resp.status_code == 201
        assert "Registration successful" in resp.json()["message"]

    # Retrieve created user
    user = db_session.query(User).filter(User.email == email).first()
    assert user is not None
    assert user.status == "unverified"
    assert user.email_verified_at is None

    # 2. Test user enumeration limit: re-registering same email returns identical response
    with (
        patch("fpl_lens.services.mailer._send_smtp_message"),
        patch(
            "fpl_lens.api.routes.auth.check_fpl_team_exists",
            new_callable=AsyncMock,
            return_value=True,
        ),
    ):
        dup_email_payload = {
            "email": email,
            "password": "AnotherPassword1234!",
            "display_name": "Different Name",
            "fpl_team_id": base_team,
        }
        dup_resp = client.post("/api/v1/auth/register", json=dup_email_payload)
        assert dup_resp.status_code == 201
        assert "Registration successful" in dup_resp.json()["message"]

    # 3. Test duplicate FPL team ID returns 409
    dup_team_payload = {
        "email": f"another_unique_{tag}@example.com",
        "password": "AnotherPassword1234!",
        "display_name": "Different Name",
        "fpl_team_id": base_team,
    }
    with patch(
        "fpl_lens.api.routes.auth.check_fpl_team_exists", new_callable=AsyncMock, return_value=True
    ):
        dup_team_resp = client.post("/api/v1/auth/register", json=dup_team_payload)
        assert dup_team_resp.status_code == 409
        assert dup_team_resp.json()["error"]["code"] == "FPL_TEAM_ALREADY_REGISTERED"

    # 4. Generate token for unverified user:
    # They can fetch /api/v1/me (to read status="unverified"), but cannot access verified-only actions (like account deletion)
    unverified_token = create_access_token(user)
    headers = {"Authorization": f"Bearer {unverified_token}"}
    me_resp = client.get("/api/v1/me", headers=headers)
    assert me_resp.status_code == 200
    assert me_resp.json()["status"] == "unverified"

    del_resp = client.delete("/api/v1/me", headers=headers)
    assert del_resp.status_code == 403
    assert del_resp.json()["error"]["code"] == "EMAIL_NOT_VERIFIED"
