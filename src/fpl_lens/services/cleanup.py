from datetime import UTC, datetime, timedelta
from typing import Any, cast

from sqlalchemy import ColumnElement, delete
from sqlalchemy.orm import Session

from fpl_lens.db.models import User
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
