import secrets
import tempfile
import uuid
from datetime import UTC, datetime
from pathlib import Path

from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from fpl_lens.db.models import AuthIdentity, User
from fpl_lens.services.backup import (
    decrypt_backup,
    export_backup_to_file,
    export_users_and_identities,
    restore_backup_from_file,
)
from fpl_lens.services.hasher import hash_password, verify_password


def test_export_and_restore_workflow(client: TestClient, db_session: Session):
    tag = uuid.uuid4().hex[:6]
    test_email = f"backup_restore_{tag}@example.com"
    test_password = "RestoreSecretPass123!"
    team_id = secrets.randbelow(1_000_000) + 8_500_000
    user_id = uuid.uuid4()

    user = User(
        id=user_id,
        email=test_email,
        password_hash=hash_password(test_password),
        display_name="Restore Tester",
        fpl_team_id=team_id,
        status="active",
        email_verified_at=datetime.now(UTC),
    )
    db_session.add(user)
    db_session.commit()

    ident = AuthIdentity(
        user_id=user_id,
        provider="email",
        provider_subject=test_email,
    )
    db_session.add(ident)
    db_session.commit()

    # 1. Export in-memory structure
    data = export_users_and_identities(db_session)
    assert data["metadata"]["users_count"] >= 1
    found_user = next((u for u in data["users"] if u["email"] == test_email), None)
    assert found_user is not None
    assert found_user["fpl_team_id"] == team_id

    # 2. Export to encrypted file
    with tempfile.TemporaryDirectory() as tmp_dir:
        backup_path = Path(tmp_dir) / "test_backup.enc"
        custom_key = "custom-secret-key-for-test-32-chars-ok"
        export_backup_to_file(db_session, backup_path, key=custom_key)
        assert backup_path.exists()
        assert backup_path.stat().st_size > 0

        # Verify file is truly encrypted (not raw JSON)
        raw_bytes = backup_path.read_bytes()
        assert b"\"email\"" not in raw_bytes
        assert b"\"fpl_team_id\"" not in raw_bytes

        # Decrypt check
        decrypted = decrypt_backup(raw_bytes, key=custom_key)
        assert "users" in decrypted
        assert "auth_identities" in decrypted

        # 3. Simulate restore
        result = restore_backup_from_file(db_session, backup_path, key=custom_key)
        assert "restored_users" in result
        assert "restored_identities" in result

        # 4. Confirm account can sign in / password verified
        stmt = select(User).where(User.email == test_email)
        restored_user = db_session.execute(stmt).scalar_one_or_none()
        assert restored_user is not None
        assert verify_password(test_password, restored_user.password_hash)

        # Login endpoint verification
        resp = client.post(
            "/api/v1/auth/login",
            json={"email": test_email, "password": test_password},
        )
        assert resp.status_code == 200
        assert "access_token" in resp.json()
