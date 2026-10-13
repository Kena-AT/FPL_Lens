from datetime import UTC, datetime, timedelta
from typing import Any

from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from fpl_lens.db.models import CacheEntry


def get_cached_value(db: Session, key: str) -> dict[str, Any] | list[Any] | None:
    """Returns the cached value if not expired, else None."""
    now = datetime.now(UTC)
    stmt = select(CacheEntry).where(CacheEntry.cache_key == key, CacheEntry.expires_at > now)
    entry = db.execute(stmt).scalar_one_or_none()
    return entry.value if entry else None


def get_stale_cached_value(db: Session, key: str) -> tuple[dict[str, Any] | list[Any], datetime] | None:
    """
    Returns the cached value and its expiration/timestamp even if expired.
    Used for stale fallback when FPL upstream is unavailable.
    """
    stmt = select(CacheEntry).where(CacheEntry.cache_key == key)
    entry = db.execute(stmt).scalar_one_or_none()
    if entry:
        return entry.value, entry.expires_at
    return None


def set_cached_value(
    db: Session,
    key: str,
    value: dict[str, Any] | list[Any],
    ttl_seconds: int,
) -> None:
    """Upserts a JSONB cache entry with a TTL."""
    now = datetime.now(UTC)
    expires_at = now + timedelta(seconds=ttl_seconds)

    stmt = insert(CacheEntry).values(
        cache_key=key,
        value=value,
        expires_at=expires_at,
    )
    stmt = stmt.on_conflict_do_update(
        index_elements=["cache_key"],
        set_={
            "value": stmt.excluded.value,
            "expires_at": stmt.excluded.expires_at,
        },
    )
    db.execute(stmt)
    db.commit()


def delete_cached_value(db: Session, key: str) -> None:
    """Deletes a single cache entry."""
    stmt = delete(CacheEntry).where(CacheEntry.cache_key == key)
    db.execute(stmt)
    db.commit()
