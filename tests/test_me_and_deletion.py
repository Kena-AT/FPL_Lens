import secrets
import uuid
from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.db.models import User
from fpl_lens.services.cleanup import cleanup_expired_accounts
from fpl_lens.services.token import create_access_token


def test_me_profile_and_authorization_404(client: TestClient, db_session: Session):
    tag = uuid.uuid4().hex[:6]
    team1 = secrets.randbelow(1_000_000) + 3_000_000
    team2 = team1 + 1

    user1 = User(
        id=uuid.uuid4(),
        email=f"me_user1_{tag}@example.com",
        display_name="User One",
        fpl_team_id=team1,
        status="active",
        email_verified_at=datetime.now(UTC),
    )
    user2 = User(
        id=uuid.uuid4(),
        email=f"me_user2_{tag}@example.com",
        display_name="User Two",
        fpl_team_id=team2,
        status="active",
        email_verified_at=datetime.now(UTC),
    )
    db_session.add_all([user1, user2])
    db_session.commit()

    token1 = create_access_token(user1)
    headers1 = {"Authorization": f"Bearer {token1}"}

    # 1. GET /api/v1/me returns user1 profile
    resp_me = client.get("/api/v1/me", headers=headers1)
    assert resp_me.status_code == 200
    assert resp_me.json()["email"] == f"me_user1_{tag}@example.com"
    assert resp_me.json()["fpl_team_id"] == team1

    # 2. GET /api/v1/me/{user2.id} returns 404 (another user's identifier returns 404 per AGENTS.md §9 and Backend Design §12.2)
    resp_other = client.get(f"/api/v1/me/{user2.id}", headers=headers1)
    assert resp_other.status_code == 404
    assert resp_other.json()["error"]["code"] == "NOT_FOUND"


def test_account_deletion_and_cleanup(client: TestClient, db_session: Session):
    tag = uuid.uuid4().hex[:6]
    team = secrets.randbelow(1_000_000) + 4_000_000

    user = User(
        id=uuid.uuid4(),
        email=f"delete_user_{tag}@example.com",
        display_name="Delete Tester",
        fpl_team_id=team,
        status="active",
        email_verified_at=datetime.now(UTC),
    )
    db_session.add(user)
    db_session.commit()

    user_id = user.id
    token = create_access_token(user)
    headers = {"Authorization": f"Bearer {token}"}

    # Request deletion
    resp_del = client.delete("/api/v1/me", headers=headers)
    assert resp_del.status_code == 200
    assert "3 days" in resp_del.json()["message"]

    # Verify tokens fail immediately
    resp_after = client.get("/api/v1/me", headers=headers)
    assert resp_after.status_code == 401
    assert resp_after.json()["error"]["code"] == "UNAUTHENTICATED"

    # Test cleanup job after 3 days
    # Artificially age the deletion request to 4 days ago
    user.deletion_requested_at = datetime.now(UTC) - timedelta(days=4)
    db_session.commit()

    stats = cleanup_expired_accounts(db_session, grace_days=3)
    assert stats["pending_deletion_deleted"] >= 1

    # Verify user record is hard-deleted from DB
    deleted_user = db_session.query(User).filter(User.id == user_id).first()
    assert deleted_user is None
