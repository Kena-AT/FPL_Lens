import hashlib
import hmac
import secrets
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from fpl_lens.config import settings
from fpl_lens.db.models import EmailCode, RefreshToken, User
from fpl_lens.logging import logger


def generate_six_digit_code() -> str:
    """Generates a cryptographically secure 6-digit numeric string."""
    return f"{secrets.randbelow(1_000_000):06d}"


def hash_token(token: str) -> bytes:
    """Returns SHA-256 byte digest for a raw token or code."""
    return hashlib.sha256(token.encode("utf-8")).digest()


# --- JWT Access Tokens (Two-Key Rotation) ---


def create_access_token(user: User) -> str:
    """
    Creates a 15-minute JWT access token signed with the active key.
    Includes sub, aud, iss, exp, iat, jti, fpl_team_id, and status.
    """
    now = datetime.now(UTC)
    expires_at = now + timedelta(seconds=settings.ACCESS_TOKEN_TTL_SECONDS)
    payload = {
        "sub": str(user.id),
        "iss": settings.JWT_ISSUER,
        "aud": settings.JWT_AUDIENCE,
        "iat": int(now.timestamp()),
        "exp": int(expires_at.timestamp()),
        "jti": str(uuid.uuid4()),
        "fpl_team_id": user.fpl_team_id,
        "status": user.status,
    }
    key = settings.get_effective_jwt_signing_key()
    return jwt.encode(payload, key, algorithm="HS256")


def decode_access_token(token: str) -> dict[str, Any]:
    """
    Decodes and validates a JWT access token using two-key rotation.
    First tries the current signing key, then falls back to the previous key.
    """
    current_key = settings.get_effective_jwt_signing_key()
    options = {
        "verify_signature": True,
        "verify_exp": True,
        "verify_aud": True,
        "verify_iss": True,
    }

    try:
        return jwt.decode(
            token,
            current_key,
            algorithms=["HS256"],
            audience=settings.JWT_AUDIENCE,
            issuer=settings.JWT_ISSUER,
            options=options,
        )
    except jwt.InvalidSignatureError:
        prev_key = settings.get_effective_jwt_previous_key()
        if prev_key:
            return jwt.decode(
                token,
                prev_key,
                algorithms=["HS256"],
                audience=settings.JWT_AUDIENCE,
                issuer=settings.JWT_ISSUER,
                options=options,
            )
        raise


# --- Opaque Refresh Tokens (256-bit, Rotation & Family Revocation) ---


def generate_raw_refresh_token() -> str:
    """Generates a 256-bit opaque URL-safe refresh token."""
    return secrets.token_urlsafe(32)


def issue_refresh_token(
    db: Session, user_id: uuid.UUID, family_id: uuid.UUID | None = None
) -> tuple[str, RefreshToken]:
    """Issues and persists a new hashed refresh token."""
    raw_token = generate_raw_refresh_token()
    token_digest = hash_token(raw_token)
    fam_id = family_id or uuid.uuid4()

    expires_at = datetime.now(UTC) + timedelta(days=settings.REFRESH_TOKEN_TTL_DAYS)

    refresh_row = RefreshToken(
        id=uuid.uuid4(),
        user_id=user_id,
        family_id=fam_id,
        token_hash=token_digest,
        issued_at=datetime.now(UTC),
        expires_at=expires_at,
        revoked_at=None,
        replaced_by=None,
    )
    db.add(refresh_row)
    db.commit()
    db.refresh(refresh_row)
    return raw_token, refresh_row


def rotate_refresh_token(db: Session, raw_token: str) -> tuple[str, RefreshToken, uuid.UUID]:
    """
    Validates and rotates a refresh token.
    If reuse of a revoked token is detected, revokes the ENTIRE family immediately.
    Returns: (new_raw_token, new_refresh_row, user_id)
    Raises ValueError on invalid token, expired token, or reuse detection.
    """
    token_digest = hash_token(raw_token)
    stmt = select(RefreshToken).where(RefreshToken.token_hash == token_digest)
    row = db.execute(stmt).scalar_one_or_none()

    if not row:
        raise ValueError("Invalid refresh token")

    # Reuse detection: if this token was already revoked, revoke the whole family
    if row.revoked_at is not None:
        logger.warning(
            "Refresh token reuse detected for family %s. Revoking whole family.",
            row.family_id,
        )
        revoke_refresh_family(db, row.family_id)
        raise ValueError("Refresh token reuse detected: entire session family revoked")

    # Expiration check
    if row.expires_at <= datetime.now(UTC):
        raise ValueError("Refresh token expired")

    # Valid token: generate replacement in the same family
    new_raw, new_row = issue_refresh_token(db, user_id=row.user_id, family_id=row.family_id)

    # Mark current token replaced & revoked
    row.revoked_at = datetime.now(UTC)
    row.replaced_by = new_row.id
    db.commit()

    return new_raw, new_row, row.user_id


def revoke_refresh_family(db: Session, family_id: uuid.UUID) -> None:
    """Revokes all refresh tokens in a given family."""
    now = datetime.now(UTC)
    stmt = (
        update(RefreshToken)
        .where(RefreshToken.family_id == family_id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=now)
    )
    db.execute(stmt)
    db.commit()


def revoke_all_user_tokens(db: Session, user_id: uuid.UUID) -> None:
    """Revokes all refresh tokens for a user across all families."""
    now = datetime.now(UTC)
    stmt = (
        update(RefreshToken)
        .where(RefreshToken.user_id == user_id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=now)
    )
    db.execute(stmt)
    db.commit()


# --- Email Verification & Password Reset Codes ---


def create_and_store_email_code(
    db: Session,
    user_id: uuid.UUID,
    purpose: str = "verify_email",
    expiry_minutes: int = 10,
) -> str:
    """Generates a 6-digit code, stores its SHA-256 digest in email_codes, and returns the raw code."""
    raw_code = generate_six_digit_code()
    code_digest = hash_token(raw_code)
    expires_at = datetime.now(UTC) + timedelta(minutes=expiry_minutes)

    email_code = EmailCode(
        id=uuid.uuid4(),
        user_id=user_id,
        purpose=purpose,
        code_hash=code_digest,
        attempts=0,
        expires_at=expires_at,
        used_at=None,
    )
    db.add(email_code)
    db.commit()
    return raw_code


def verify_email_code(
    db: Session,
    user_id: uuid.UUID,
    candidate_code: str,
    purpose: str = "verify_email",
) -> bool:
    """
    Verifies a 6-digit code for a user and purpose.
    Enforces 10-minute expiry and max 5 attempts. Invalidates after 5 wrong attempts.
    """
    candidate_digest = hash_token(candidate_code)

    # Get latest unused code for this user and purpose
    stmt = (
        select(EmailCode)
        .where(
            EmailCode.user_id == user_id,
            EmailCode.purpose == purpose,
            EmailCode.used_at.is_(None),
        )
        .order_by(EmailCode.created_at.desc())
        .limit(1)
    )
    row = db.execute(stmt).scalar_one_or_none()

    if not row:
        return False

    # Check expiration
    if row.expires_at <= datetime.now(UTC):
        return False

    # Check attempts: after 5 attempts, code is permanently invalidated
    if row.attempts >= 5:
        return False

    # Increment attempt count
    row.attempts += 1

    # Constant-time comparison
    if hmac.compare_digest(row.code_hash, candidate_digest):
        row.used_at = datetime.now(UTC)
        db.commit()
        return True

    db.commit()
    return False
