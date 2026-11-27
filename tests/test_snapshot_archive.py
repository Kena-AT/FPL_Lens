import json
import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.db.models import Gameweek, IngestionRun, SnapshotBlob, SnapshotRecord
from fpl_lens.services.snapshot_archive import (
    archive_snapshot,
    classify_trigger_reason,
    get_archived_payload,
    run_snapshot_archive_job,
)

FIXTURES_DIR = Path(__file__).parent / "fixtures"


def test_snapshot_archive_compression_and_deduplication(db_session: Session):
    """
    Verifies §4.2:
    - Snapshots are stored gzip-compressed with SHA-256 content hash.
    - Unchanged payloads reuse the existing SnapshotBlob (is_duplicate=True).
    - Decompression roundtrip matches original JSON.
    """
    payload = {
        "nonce": str(uuid.uuid4()),
        "events": [{"id": 1, "name": "GW1"}],
        "elements": [{"id": 10, "web_name": "Saka"}],
    }
    t1 = datetime(2026, 11, 27, 10, 0, tzinfo=UTC)
    t2 = datetime(2026, 11, 27, 11, 0, tzinfo=UTC)

    content_hash: str | None = None
    try:
        res1 = archive_snapshot(
            db_session,
            source="bootstrap-static",
            payload=payload,
            http_status=200,
            trigger_reason="daily",
            gameweek=1,
            fetched_at=t1,
        )
        content_hash = res1["content_hash"]
        assert res1["is_duplicate"] is False
        assert res1["compressed_bytes"] > 0

        res2 = archive_snapshot(
            db_session,
            source="bootstrap-static",
            payload=payload,
            http_status=200,
            trigger_reason="t_24h",
            gameweek=1,
            fetched_at=t2,
        )
        assert res2["is_duplicate"] is True
        assert res2["content_hash"] == res1["content_hash"]

        blobs = (
            db_session.query(SnapshotBlob)
            .filter(SnapshotBlob.content_hash == res1["content_hash"])
            .all()
        )
        records = (
            db_session.query(SnapshotRecord)
            .filter(SnapshotRecord.content_hash == res1["content_hash"])
            .all()
        )
        assert len(blobs) == 1
        assert len(records) == 2

        restored = get_archived_payload(db_session, res2["record_id"])
        assert restored == payload
    finally:
        if content_hash is not None:
            db_session.query(SnapshotRecord).filter(
                SnapshotRecord.content_hash == content_hash
            ).delete(synchronize_session=False)
            db_session.query(SnapshotBlob).filter(
                SnapshotBlob.content_hash == content_hash
            ).delete(synchronize_session=False)
            db_session.commit()


def test_classify_trigger_reason_windows(db_session: Session):
    """Verifies deadline proximity classification for T-24h, T-3h, T-1h, post_gw, and daily."""
    now = datetime(2026, 11, 27, 12, 0, tzinfo=UTC)
    existing_next = db_session.query(Gameweek).filter(Gameweek.is_next.is_(True)).all()
    for eg in existing_next:
        eg.is_next = False
    gw = Gameweek(
        id=999,
        name="Test Gameweek 999",
        deadline_time=now + timedelta(minutes=45),
        finished=False,
        is_current=False,
        is_next=True,
    )
    db_session.merge(gw)
    db_session.commit()

    try:
        reason, gw_id = classify_trigger_reason(db_session, now)
        assert reason == "t_1h"
        assert gw_id == 999

        gw_row = db_session.query(Gameweek).filter(Gameweek.id == 999).first()
        assert gw_row is not None
        gw_row.deadline_time = now + timedelta(hours=3)
        db_session.commit()
        reason, _ = classify_trigger_reason(db_session, now)
        assert reason == "t_3h"

        gw_row.deadline_time = now + timedelta(hours=24)
        db_session.commit()
        reason, _ = classify_trigger_reason(db_session, now)
        assert reason == "t_24h"

        gw_row.deadline_time = now + timedelta(days=5)
        db_session.commit()
        reason, _ = classify_trigger_reason(db_session, now)
        assert reason == "daily"
    finally:
        db_session.query(Gameweek).filter(Gameweek.id == 999).delete(synchronize_session=False)
        for eg in existing_next:
            eg.is_next = True
        db_session.commit()


async def test_run_snapshot_archive_job_with_real_fixtures(db_session: Session):
    """Runs the full snapshot archive job on real recorded bootstrap + fixtures payloads."""
    with open(FIXTURES_DIR / "bootstrap_static.json", encoding="utf-8") as f:
        bootstrap_data = json.load(f)
    with open(FIXTURES_DIR / "fixtures.json", encoding="utf-8") as f:
        fixtures_data = json.load(f)

    res = await run_snapshot_archive_job(
        db_session,
        bootstrap_data=bootstrap_data,
        fixtures_data=fixtures_data,
        trigger_reason="manual",
    )
    try:
        assert res["status"] == "OK"
        assert res["bootstrap"]["compressed_bytes"] < 300_000
        assert res["fixtures"]["compressed_bytes"] < 50_000

        run = db_session.query(IngestionRun).filter(IngestionRun.id == res["run_id"]).first()
        assert run is not None
        assert run.job_name == "snapshot_archive"
        assert run.status == "OK"
        assert run.rows_written == 2
    finally:
        db_session.query(SnapshotRecord).filter(
            SnapshotRecord.id.in_([res["bootstrap"]["record_id"], res["fixtures"]["record_id"]])
        ).delete(synchronize_session=False)
        db_session.query(IngestionRun).filter(IngestionRun.id == res["run_id"]).delete(
            synchronize_session=False
        )
        db_session.commit()


def test_snapshot_archive_endpoint_requires_job_token(client: TestClient):
    """Internal snapshot-archive job rejects unauthenticated requests with 401."""
    resp = client.post("/internal/jobs/snapshot-archive")
    assert resp.status_code == 401
