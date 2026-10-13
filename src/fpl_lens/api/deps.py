import uuid
from typing import Annotated

from fastapi import Depends, Header, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from fpl_lens.api.errors import AppError
from fpl_lens.db.models import User
from fpl_lens.db.session import get_db
from fpl_lens.services.token import decode_access_token


def get_client_ip(request: Request) -> str:
    """Extracts client IP address from proxy headers or direct client host."""
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    if request.client:
        return request.client.host
    return "127.0.0.1"


def get_token_from_header(authorization: Annotated[str | None, Header()] = None) -> str:
    """Extracts Bearer token from Authorization header."""
    if not authorization:
        raise AppError(
            code="UNAUTHENTICATED",
            message="Missing authorization header",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise AppError(
            code="UNAUTHENTICATED",
            message="Invalid authorization header format. Expected 'Bearer <token>'",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )
    return parts[1]


def get_current_user(
    token: Annotated[str, Depends(get_token_from_header)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    """
    Decodes JWT token and retrieves the corresponding user.
    Allows unverified users (used by verify-email and resend endpoints).
    Rejects deleted users immediately.
    """
    try:
        payload = decode_access_token(token)
    except Exception as exc:
        raise AppError(
            code="UNAUTHENTICATED",
            message="Invalid or expired access token",
            status_code=status.HTTP_401_UNAUTHORIZED,
        ) from exc

    user_id_str = payload.get("sub")
    if not user_id_str:
        raise AppError(
            code="UNAUTHENTICATED",
            message="Token subject missing",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    try:
        user_uuid = uuid.UUID(user_id_str)
    except ValueError as exc:
        raise AppError(
            code="UNAUTHENTICATED",
            message="Invalid user identifier",
            status_code=status.HTTP_401_UNAUTHORIZED,
        ) from exc

    stmt = select(User).where(User.id == user_uuid)
    user = db.execute(stmt).scalar_one_or_none()

    if not user:
        raise AppError(
            code="UNAUTHENTICATED",
            message="User not found",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    # Deleted account check: tokens fail immediately
    if user.status == "pending_deletion" or user.deletion_requested_at is not None:
        raise AppError(
            code="UNAUTHENTICATED",
            message="Account has been deleted",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    return user


def get_verified_user(
    user: Annotated[User, Depends(get_current_user)],
) -> User:
    """
    Ensures user is active and has verified their email address.
    Unverified accounts return 403 EMAIL_NOT_VERIFIED.
    """
    if user.status != "active" or user.email_verified_at is None:
        raise AppError(
            code="EMAIL_NOT_VERIFIED",
            message="Email has not been verified. Please complete verification.",
            status_code=status.HTTP_403_FORBIDDEN,
        )
    return user


get_current_active_user = get_verified_user

