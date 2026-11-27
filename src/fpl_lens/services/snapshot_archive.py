"""
Point-in-time public FPL snapshot archive service per Engine Design §4.2.
Stores immutable, gzip-compressed copies of bootstrap-static and fixtures
with SHA-256 content-hash deduplication. Contains zero user data.
"""

from __future__ import annotations

import gzip
import hashlib
import json
from datetime import UTC, datetime, timedelta
from typing import Any, cast

from sqlalchemy.orm import Session

from fpl_lens.db.models import Gameweek, IngestionRun, SnapshotBlob, SnapshotRecord
from fpl_lens.logging import logger
from fpl_lens.services.fpl_client import fpl_client


def _canonical_json_bytes(payload: dict[str, Any] | list[Any]) -> bytes:
    """Serializes JSON deterministically for stable content hashing."""
    return json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")


def classify_trigger_reason(db: Session, now: datetime) -> tuple[str, int | None]:
    """
    Classifies a scheduled snapshot run into one of the §4.2 archive windows:
      - t_1h: within (0, 90] minutes before next deadline
      - t_3h: within (90m, 4h] before next deadline
      - t_24h: within (22h, 26h] before next deadline
      - post_gw: current GW finished and within 36h after deadline (09:00 UK finalisation window)
      - daily: regular daily snapshot
    Returns (trigger_reason, gameweek_id).
    """
    next_gw = db.query(Gameweek).filter(Gameweek.is_next.is_(True)).first()
    if next_gw is None:
        next_gw = (
            db.query(Gameweek)
            .filter(Gameweek.deadline_time > now)
            .order_by(Gameweek.deadline_time.asc())
            .first()
        )

    if next_gw is not None and next_gw.deadline_time is not None:
        dl = next_gw.deadline_time
        if dl.tzinfo is None:
            dl = dl.replace(tzinfo=UTC)
        delta = dl - now
        if timedelta(minutes=0) < delta <= timedelta(minutes=90):
            return "t_1h", int(next_gw.id)
        if timedelta(minutes=90) < delta <= timedelta(hours=4):
            return "t_3h", int(next_gw.id)
        if timedelta(hours=22) <= delta <= timedelta(hours=26):
            return "t_24h", int(next_gw.id)

    cur_gw = db.query(Gameweek).filter(Gameweek.is_current.is_(True)).first()
    if cur_gw is not None and cur_gw.finished:
        already_archived_post_gw = (
            db.query(SnapshotRecord)
            .filter(
                SnapshotRecord.trigger_reason == "post_gw",
                SnapshotRecord.gameweek == int(cur_gw.id),
            )
            .first()
        )
        if already_archived_post_gw is None:
            return "post_gw", int(cur_gw.id)

    target_gw = int(next_gw.id) if next_gw is not None else (int(cur_gw.id) if cur_gw else None)
    return "daily", target_gw


def archive_snapshot(
    db: Session,
    *,
    source: str,
    payload: dict[str, Any] | list[Any],
    http_status: int = 200,
    trigger_reason: str = "manual",
    gameweek: int | None = None,
    fetched_at: datetime | None = None,
) -> dict[str, Any]:
    """
    Archives a single public FPL payload into snapshot_blobs (deduplicated)
    and snapshot_records (immutable timestamped entry).
    """
    ts = fetched_at or datetime.now(UTC)
    raw = _canonical_json_bytes(payload)
    content_hash = hashlib.sha256(raw).hexdigest()

    existing_blob = (
        db.query(SnapshotBlob).filter(SnapshotBlob.content_hash == content_hash).first()
    )
    is_duplicate = existing_blob is not None

    if existing_blob is None:
        compressed = gzip.compress(raw, compresslevel=9)
        blob = SnapshotBlob(
            content_hash=content_hash,
            source=source,
            payload_gzip=compressed,
            raw_bytes=len(raw),
            compressed_bytes=len(compressed),
            created_at=ts,
        )
        db.add(blob)
        db.flush()
        compressed_bytes = len(compressed)
    else:
        compressed_bytes = int(existing_blob.compressed_bytes)

    record = SnapshotRecord(
        source=source,
        fetched_at=ts,
        http_status=http_status,
        content_hash=content_hash,
        trigger_reason=trigger_reason,
        gameweek=gameweek,
        is_duplicate=is_duplicate,
    )
    db.add(record)
    db.commit()
    db.refresh(record)

    return {
        "record_id": int(record.id),
        "source": source,
        "content_hash": content_hash,
        "raw_bytes": len(raw),
        "compressed_bytes": compressed_bytes,
        "is_duplicate": is_duplicate,
        "trigger_reason": trigger_reason,
        "gameweek": gameweek,
    }


def get_archived_payload(db: Session, record_id: int) -> dict[str, Any] | list[Any]:
    """Decompresses and returns the JSON payload for a stored SnapshotRecord."""
    record = db.query(SnapshotRecord).filter(SnapshotRecord.id == record_id).first()
    if record is None:
        raise ValueError(f"SnapshotRecord {record_id} not found")
    blob = db.query(SnapshotBlob).filter(SnapshotBlob.content_hash == record.content_hash).first()
    if blob is None:
        raise ValueError(f"SnapshotBlob {record.content_hash} not found")
    return json.loads(gzip.decompress(blob.payload_gzip).decode("utf-8"))


async def run_snapshot_archive_job(
    db: Session,
    *,
    bootstrap_data: dict[str, Any] | None = None,
    fixtures_data: list[dict[str, Any]] | None = None,
    trigger_reason: str = "scheduled",
    now: datetime | None = None,
) -> dict[str, Any]:
    """
    Fetches and archives both bootstrap-static and fixtures snapshots.
    Logs an IngestionRun row with job_name='snapshot_archive'.
    """
    ts = now or datetime.now(UTC)
    run = IngestionRun(
        job_name="snapshot_archive",
        started_at=ts,
        status="RUNNING",
        rows_written=0,
    )
    db.add(run)
    db.commit()
    db.refresh(run)

    try:
        resolved_reason = trigger_reason
        gw_id: int | None = None
        if trigger_reason == "scheduled":
            resolved_reason, gw_id = classify_trigger_reason(db, ts)

        bs = (
            bootstrap_data
            if bootstrap_data is not None
            else await fpl_client.get_bootstrap_static(enforce_throttle=False)
        )
        fx = (
            fixtures_data
            if fixtures_data is not None
            else await fpl_client.get_fixtures()
        )

        bs_res = archive_snapshot(
            db,
            source="bootstrap-static",
            payload=bs,
            http_status=200,
            trigger_reason=resolved_reason,
            gameweek=gw_id,
            fetched_at=ts,
        )
        fx_res = archive_snapshot(
            db,
            source="fixtures",
            payload=fx,
            http_status=200,
            trigger_reason=resolved_reason,
            gameweek=gw_id,
            fetched_at=ts,
        )

        run_any = cast(Any, run)
        run_any.status = "OK"
        run_any.rows_written = 2
        run_any.finished_at = datetime.now(UTC)
        db.commit()

        logger.info(
            "Snapshot archive completed (%s, gw=%s): bootstrap=%dB, fixtures=%dB",
            resolved_reason,
            gw_id,
            bs_res["compressed_bytes"],
            fx_res["compressed_bytes"],
        )

        return {
            "run_id": int(run.id),
            "status": "OK",
            "trigger_reason": resolved_reason,
            "gameweek": gw_id,
            "bootstrap": bs_res,
            "fixtures": fx_res,
        }
    except Exception as exc:
        db.rollback()
        failed_run = db.query(IngestionRun).filter(IngestionRun.id == run.id).first()
        if failed_run is not None:
            failed_any = cast(Any, failed_run)
            failed_any.status = "FAILED"
            failed_any.error_summary = str(exc)[:500]
            failed_any.finished_at = datetime.now(UTC)
            db.commit()
        logger.error("Snapshot archive failed: %s", exc)
        raise
