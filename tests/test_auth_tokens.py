import secrets
import uuid
from datetime import UTC, datetime, timedelta

import jwt
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.config import settings
from fpl_lens.db.models import User
from fpl_lens.services.hasher import hash_password
from fpl_lens.services.token import (
    decode_access_token,
    issue_refresh_token,
)


def test_refresh_token_rotation_and_reuse_detection(client: TestClient, db_session: Session):
    tag = uuid.uuid4().hex[:6]
    team_id = secrets.randbelow(1_000_000) + 8_000_000
    user = User(
        id=uuid.uuid4(),
        email=f"token_rotation_{tag}@example.com",
        password_hash=hash_password("ValidPassword123!"),
        display_name="Token Tester",
        fpl_team_id=team_id,
        status="active",
        email_verified_at=datetime.now(UTC),
    )
    db_session.add(user)
    db_session.commit()

    # Issue initial refresh token
    raw_token_1, _ = issue_refresh_token(db_session, user.id)

    # 1. First rotation with valid token: succeeds
    resp1 = client.post("/api/v1/auth/refresh", json={"refresh_token": raw_token_1})
    assert resp1.status_code == 200
    data1 = resp1.json()
    raw_token_2 = data1["refresh_token"]
    assert raw_token_2 != raw_token_1

    # 2. Second rotation with new token: succeeds
    resp2 = client.post("/api/v1/auth/refresh", json={"refresh_token": raw_token_2})
    assert resp2.status_code == 200
    data2 = resp2.json()
    raw_token_3 = data2["refresh_token"]

    # 3. REUSE DETECTION: submit raw_token_1 (already rotated/revoked)
    # Must fail with 401 and revoke the entire family
    resp_reuse = client.post("/api/v1/auth/refresh", json={"refresh_token": raw_token_1})
    assert resp_reuse.status_code == 401
    assert "reuse detected" in resp_reuse.json()["error"]["message"].lower()

    # 4. Attempting to use raw_token_3 (previously valid token from that same family) must now also fail
    # because the entire family was revoked upon reuse detection!
    resp_family_dead = client.post("/api/v1/auth/refresh", json={"refresh_token": raw_token_3})
    assert resp_family_dead.status_code == 401


def test_two_key_jwt_rotation(db_session: Session):
    tag = uuid.uuid4().hex[:6]
    team_id = secrets.randbelow(1_000_000) + 9_000_000
    user = User(
        id=uuid.uuid4(),
        email=f"jwt_rotation_{tag}@example.com",
        fpl_team_id=team_id,
        status="active",
    )

    # Set up keys in settings
    old_key = "previous-signing-key-fpl-lens-12345"
    current_key = "current-signing-key-fpl-lens-67890"

    settings.JWT_PREVIOUS_KEY = old_key
    settings.JWT_SIGNING_KEY = current_key

    # Create a token signed with the OLD key
    now = datetime.now(UTC)
    payload = {
        "sub": str(user.id),
        "iss": settings.JWT_ISSUER,
        "aud": settings.JWT_AUDIENCE,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=15)).timestamp()),
        "jti": str(uuid.uuid4()),
        "fpl_team_id": user.fpl_team_id,
        "status": user.status,
    }
    old_token = jwt.encode(payload, old_key, algorithm="HS256")

    # Decoding should succeed by falling back to the previous key!
    decoded = decode_access_token(old_token)
    assert decoded["sub"] == str(user.id)
