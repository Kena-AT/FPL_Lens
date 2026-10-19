import io
import json
import logging
import secrets
import uuid
from unittest.mock import AsyncMock, patch

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.db.models import AuditEvent
from fpl_lens.logging import JsonFormatter, RedactionFilter
from fpl_lens.services.audit import hash_ip


def test_audit_events_and_log_redaction_for_auth(client: TestClient, db_session: Session):
    tag = uuid.uuid4().hex[:6]
    team_id = secrets.randbelow(1_000_000) + 1_500_000

    # Set up memory stream logger with RedactionFilter
    stream = io.StringIO()
    handler = logging.StreamHandler(stream)
    handler.setFormatter(JsonFormatter())
    handler.addFilter(RedactionFilter())

    root_logger = logging.getLogger()
    root_logger.addHandler(handler)

    password = "SuperSecretPassword123!"
    reg_payload = {
        "email": f"audit_user_{tag}@example.com",
        "password": password,
        "display_name": "Audit Tester",
        "fpl_team_id": team_id,
    }

    with (
        patch("fpl_lens.services.mailer._send_smtp_message"),
        patch(
            "fpl_lens.api.routes.auth.check_fpl_team_exists",
            new_callable=AsyncMock,
            return_value=True,
        ),
    ):
        client.post("/api/v1/auth/register", json=reg_payload)

    handler.flush()
    log_output = stream.getvalue()

    # 1. Assert plaintext password does not appear in logs
    assert password not in log_output

    # 2. Check audit events: verify password and codes are not in metadata
    events = db_session.query(AuditEvent).all()
    assert len(events) >= 1

    for ev in events:
        meta_str = json.dumps(ev.audit_metadata or {})
        assert password not in meta_str
        assert "password" not in meta_str.lower()
        assert "token" not in meta_str.lower()
        assert "code" not in meta_str.lower()

        # If IP was provided, it must be hashed (not plaintext)
        if ev.ip_hash:
            assert isinstance(ev.ip_hash, bytes)
            assert ev.ip_hash == hash_ip("testclient") or len(ev.ip_hash) == 32
