import base64
import hashlib
import json
import uuid
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from cryptography.fernet import Fernet
from sqlalchemy import select
from sqlalchemy.orm import Session

from fpl_lens.config import settings
from fpl_lens.db.models import AuthIdentity, User


def get_fernet(key: str | None = None) -> Fernet:
    """
    Returns a Fernet instance for AES-128-CBC + HMAC encryption.
    Derives a standard 32-byte urlsafe base64 key using SHA-256 over the provided or configured key.
    """
    effective_key = key or settings.get_effective_backup_encryption_key()
    digest = hashlib.sha256(effective_key.encode("utf-8")).digest()
    urlsafe_b64 = base64.urlsafe_b64encode(digest)
    return Fernet(urlsafe_b64)


def export_users_and_identities(db: Session) -> dict[str, Any]:
    """
    Serializes all users and auth_identities records into a structured dictionary.
    """
    users_stmt = select(User).order_by(User.created_at)
    users = db.execute(users_stmt).scalars().all()

    identities_stmt = select(AuthIdentity).order_by(AuthIdentity.id)
    identities = db.execute(identities_stmt).scalars().all()

    users_data: list[dict[str, Any]] = []
    for u in users:
        users_data.append(
            {
                "id": str(u.id),
                "email": u.email,
                "email_verified_at": u.email_verified_at.isoformat() if u.email_verified_at else None,
                "password_hash": u.password_hash,
                "display_name": u.display_name,
                "fpl_team_id": u.fpl_team_id,
                "status": u.status,
                "failed_login_count": u.failed_login_count,
                "locked_until": u.locked_until.isoformat() if u.locked_until else None,
                "deletion_requested_at": (
                    u.deletion_requested_at.isoformat() if u.deletion_requested_at else None
                ),
                "created_at": u.created_at.isoformat() if u.created_at else None,
                "updated_at": u.updated_at.isoformat() if u.updated_at else None,
            }
        )

    identities_data: list[dict[str, Any]] = []
    for ident in identities:
        identities_data.append(
            {
                "id": ident.id,
                "user_id": str(ident.user_id),
                "provider": ident.provider,
                "provider_subject": ident.provider_subject,
                "created_at": ident.created_at.isoformat() if ident.created_at else None,
            }
        )

    return {
        "metadata": {
            "version": "1.0",
            "exported_at": datetime.now(UTC).isoformat(),
            "users_count": len(users_data),
            "identities_count": len(identities_data),
        },
        "users": users_data,
        "auth_identities": identities_data,
    }


def encrypt_backup(data: dict[str, Any], key: str | None = None) -> bytes:
    """Serializes backup dictionary to JSON and encrypts via Fernet."""
    fernet = get_fernet(key)
    raw_json = json.dumps(data, separators=(",", ":")).encode("utf-8")
    return fernet.encrypt(raw_json)


def decrypt_backup(encrypted_bytes: bytes, key: str | None = None) -> dict[str, Any]:
    """Decrypts Fernet-encrypted bytes and parses the JSON dictionary."""
    fernet = get_fernet(key)
    decrypted_json = fernet.decrypt(encrypted_bytes).decode("utf-8")
    return json.loads(decrypted_json)


def export_backup_to_file(
    db: Session, output_path: str | Path, key: str | None = None
) -> Path:
    """Exports and encrypts users and identities, writing to output_path."""
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    data = export_users_and_identities(db)
    encrypted = encrypt_backup(data, key)
    path.write_bytes(encrypted)
    return path


def restore_backup_from_file(
    db: Session, input_path: str | Path, key: str | None = None
) -> dict[str, int]:
    """
    Decrypts backup from file and restores users and identities into the database.
    Existing users and identities are preserved/upserted without dropping data.
    """
    path = Path(input_path)
    encrypted = path.read_bytes()
    data = decrypt_backup(encrypted, key)

    restored_users = 0
    restored_identities = 0

    for u_dict in data.get("users", []):
        user_uuid = uuid.UUID(u_dict["id"])
        existing = db.execute(select(User).where(User.id == user_uuid)).scalar_one_or_none()
        if not existing:
            # Also check if email exists to avoid unique constraint conflict
            if u_dict["email"]:
                existing_email = db.execute(
                    select(User).where(User.email == u_dict["email"])
                ).scalar_one_or_none()
                if existing_email:
                    continue

            user = User(
                id=user_uuid,
                email=u_dict["email"],
                email_verified_at=(
                    datetime.fromisoformat(u_dict["email_verified_at"])
                    if u_dict["email_verified_at"]
                    else None
                ),
                password_hash=u_dict["password_hash"],
                display_name=u_dict["display_name"],
                fpl_team_id=u_dict["fpl_team_id"],
                status=u_dict["status"],
                failed_login_count=u_dict["failed_login_count"],
                locked_until=(
                    datetime.fromisoformat(u_dict["locked_until"])
                    if u_dict["locked_until"]
                    else None
                ),
                deletion_requested_at=(
                    datetime.fromisoformat(u_dict["deletion_requested_at"])
                    if u_dict["deletion_requested_at"]
                    else None
                ),
            )
            db.add(user)
            restored_users += 1

    db.flush()

    for ident_dict in data.get("auth_identities", []):
        user_uuid = uuid.UUID(ident_dict["user_id"])
        provider = ident_dict["provider"]
        subject = ident_dict["provider_subject"]

        existing_ident = db.execute(
            select(AuthIdentity).where(
                AuthIdentity.provider == provider,
                AuthIdentity.provider_subject == subject,
            )
        ).scalar_one_or_none()

        if not existing_ident:
            ident = AuthIdentity(
                user_id=user_uuid,
                provider=provider,
                provider_subject=subject,
            )
            db.add(ident)
            restored_identities += 1

    db.commit()

    return {
        "restored_users": restored_users,
        "restored_identities": restored_identities,
    }
