import secrets
import uuid
from unittest.mock import patch

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.config import settings


def test_google_auth_audience_rejection_and_success(client: TestClient, db_session: Session):
    settings.GOOGLE_ANDROID_CLIENT_ID = "valid-android-client-id.apps.googleusercontent.com"
    tag = uuid.uuid4().hex[:6]
    team_id = secrets.randbelow(1_000_000) + 6_000_000

    # 1. Test token from different app's audience rejected
    with patch("fpl_lens.api.routes.auth.verify_google_id_token") as mock_verify:
        mock_verify.side_effect = ValueError("Google token audience mismatch")

        resp = client.post(
            "/api/v1/auth/google",
            json={"id_token": "fake-google-token-from-other-app", "fpl_team_id": team_id},
        )
        assert resp.status_code == 401
        assert resp.json()["error"]["code"] == "INVALID_GOOGLE_TOKEN"

    # 2. Test successful Google signup with valid audience and FPL team ID
    with patch("fpl_lens.api.routes.auth.verify_google_id_token") as mock_verify:
        mock_verify.return_value = {
            "sub": f"google-sub-{tag}",
            "email": f"google_user_{tag}@gmail.com",
            "name": "Google User",
            "iss": "https://accounts.google.com",
        }

        resp_ok = client.post(
            "/api/v1/auth/google",
            json={"id_token": "valid-google-token", "fpl_team_id": team_id},
        )
        assert resp_ok.status_code == 200
        data = resp_ok.json()
        assert "access_token" in data
        assert "refresh_token" in data
