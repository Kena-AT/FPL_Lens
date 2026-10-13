import hashlib
from typing import Any

from sqlalchemy.orm import Session

from fpl_lens.db.models import AuditEvent


def hash_ip(ip: str | None) -> bytes | None:
    """Hashes client IP address using SHA-256 so raw IP is never persisted."""
    if not ip:
        return None
    return hashlib.sha256(ip.strip().encode("utf-8")).digest()


def record_audit_event(
    db: Session,
    action: str,
    actor_type: str = "user",
    actor_id: str | None = None,
    target_type: str | None = "user",
    target_id: str | None = None,
    ip: str | None = None,
    metadata: dict[str, Any] | None = None,
) -> AuditEvent:
    """
    Persists an audit event row.
    Never stores plaintext IP addresses, passwords, tokens, or codes.
    """
    clean_metadata = None
    if metadata:
        # Extra safety check: strip any sensitive keys if accidentally passed
        clean_metadata = {
            k: v
            for k, v in metadata.items()
            if not any(s in k.lower() for s in ["password", "token", "code", "secret", "key"])
        }

    event = AuditEvent(
        actor_type=actor_type,
        actor_id=actor_id,
        action=action,
        target_type=target_type,
        target_id=target_id,
        ip_hash=hash_ip(ip),
        audit_metadata=clean_metadata,
    )
    db.add(event)
    db.commit()
    return event
