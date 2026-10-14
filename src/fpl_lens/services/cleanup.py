"""
Account and data retention cleanup service per Backend Design §8.2, §9, and AGENTS.md §8.6.
Enforces the 3-day grace period for unverified accounts and account deletion requests.
Cleans up expired email codes, refresh tokens, and cache entries.
"""

from datetime import UTC, datetime, timedelta
from typing import Any, cast

from sqlalchemy import ColumnElement, delete, or_
from sqlalchemy.orm import Session

from fpl_lens.db.models import CacheEntry, EmailCode, RefreshToken, User
from fpl_lens.logging import logger


def cleanup_expired_accounts(db: Session, grace_days: int = 3) -> dict[str, int]:
    """
    Deletes unverified accounts older than grace_days (3 days)
    and pending-deletion accounts whose deletion request is older than grace_days (3 days).
    Enforces the strict 3-day grace period rule (AGENTS.md §8.6).
    """
    cutoff = datetime.now(UTC) - timedelta(days=grace_days)

    # 1. Unverified accounts older than 3 days
    unverified_stmt = (
        delete(User)
        .where(
            User.status == "unverified",
            cast(ColumnElement[bool], User.created_at <= cutoff),
        )
    )
    res_unverified: Any = db.execute(unverified_stmt)
    unverified_deleted: int = getattr(res_unverified, "rowcount", 0)

    # 2. Accounts pending deletion requested > 3 days ago
    pending_stmt = (
        delete(User)
        .where(
            User.status == "pending_deletion",
            cast(ColumnElement[bool], User.deletion_requested_at <= cutoff),
        )
    )
    res_pending: Any = db.execute(pending_stmt)
    pending_deleted: int = getattr(res_pending, "rowcount", 0)

    db.commit()

    logger.info(
        "Account cleanup completed: %d unverified and %d pending deletion accounts removed.",
        unverified_deleted,
        pending_deleted,
    )

    return {
        "unverified_deleted": unverified_deleted,
        "pending_deletion_deleted": pending_deleted,
    }


def cleanup_expired_tokens_and_codes(db: Session) -> dict[str, int]:
    """
    Deletes expired or used email verification codes, expired or revoked refresh tokens,
    and expired cache entries.
    """
    now = datetime.now(UTC)

    # 1. Email codes: expired or already used
    codes_stmt = (
        delete(EmailCode)
        .where(
            or_(
                cast(ColumnElement[bool], EmailCode.expires_at <= now),
                EmailCode.used_at.isnot(None),
            )
        )
    )
    res_codes: Any = db.execute(codes_stmt)
    codes_deleted: int = getattr(res_codes, "rowcount", 0)

    # 2. Refresh tokens: expired or revoked
    tokens_stmt = (
        delete(RefreshToken)
        .where(
            or_(
                cast(ColumnElement[bool], RefreshToken.expires_at <= now),
                RefreshToken.revoked_at.isnot(None),
            )
        )
    )
    res_tokens: Any = db.execute(tokens_stmt)
    tokens_deleted: int = getattr(res_tokens, "rowcount", 0)

    # 3. Cache entries: expired
    cache_stmt = delete(CacheEntry).where(cast(ColumnElement[bool], CacheEntry.expires_at <= now))
    res_cache: Any = db.execute(cache_stmt)
    cache_deleted: int = getattr(res_cache, "rowcount", 0)

    db.commit()

    logger.info(
        "Tokens, codes, and cache cleanup completed: %d codes, %d tokens, %d cache entries removed.",
        codes_deleted,
        tokens_deleted,
        cache_deleted,
    )

    return {
        "codes_deleted": codes_deleted,
        "tokens_deleted": tokens_deleted,
        "cache_deleted": cache_deleted,
    }


def run_full_cleanup(db: Session, grace_days: int = 3) -> dict[str, int]:
    """
    Executes the full cleanup job covering accounts, tokens, email codes, and cache entries.
    """
    acct_stats = cleanup_expired_accounts(db, grace_days=grace_days)
    token_stats = cleanup_expired_tokens_and_codes(db)
    return {**acct_stats, **token_stats}
