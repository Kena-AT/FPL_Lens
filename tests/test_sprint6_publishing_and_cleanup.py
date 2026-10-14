"""
Comprehensive tests for Sprint 6: Publishing, Scheduling, and Cleanup.

Verifies:
- Bundle generation and publishing to published_projections.
- GET /api/v1/projections/{gw} returns bundle with ETag and Cache-Control.
- GET /api/v1/projections/{gw} returns 304 Not Modified when ETag matches.
- Bundle is served from published_projections without recomputing.
- GET /api/v1/projections/{gw}/players/{fpl_id} returns single player projection.
- GET /api/v1/gameweeks/current returns current and next gameweek.
- GET /api/v1/fixtures?gw= returns filtered fixtures.
- GET /api/v1/players/search?q= returns matching players (authenticated).
- Cleanup job deletes unverified accounts older than 3 days.
- Cleanup job deletes accounts with deletion requested > 3 days ago, and keeps accounts requested < 3 days ago.
- Cleanup job deletes expired email codes, refresh tokens, and cache entries.
- Failed projection job marks ingestion_runs row as FAILED and does not publish a bundle.
- Health endpoint reports last ingestion time.
"""

import random
import uuid
from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.db.models import (
    CacheEntry,
    EmailCode,
    Fixture,
    Gameweek,
    IngestionRun,
    Player,
    PlayerFixtureStat,
    ProjectionRun,
    PublishedProjection,
    RefreshToken,
    Team,
    User,
)
from fpl_lens.engine.service import (
    ensure_model_version,
    run_projection_job,
    run_projections_for_gameweek,
)
from fpl_lens.services.cleanup import run_full_cleanup
from fpl_lens.services.token import create_access_token


def test_bundle_generation_and_publishing(db_session: Session):
    """
    Verifies bundle generation: one JSON document per gameweek,
    stored in published_projections.bundle_json, matching engine output.
    """
    now = datetime.now(UTC)

    # 1. Parents: Teams & Gameweeks
    team = Team(
        fpl_id=881,
        name="Arsenal Test",
        short_name="ARS",
        strength_attack_home=1200,
        strength_attack_away=1250,
        strength_defence_home=1150,
        strength_defence_away=1200,
    )
    opp = Team(
        fpl_id=882,
        name="Chelsea Test",
        short_name="CHE",
        strength_attack_home=1100,
        strength_attack_away=1150,
        strength_defence_home=1100,
        strength_defence_away=1150,
    )
    gw_past = Gameweek(
        id=87,
        name="Gameweek 87",
        deadline_time=now - timedelta(days=5),
        finished=True,
        is_current=False,
        is_next=False,
    )
    gw = Gameweek(
        id=88,
        name="Gameweek 88",
        deadline_time=now + timedelta(days=2),
        finished=False,
        is_current=False,
        is_next=False,
    )
    db_session.merge(team)
    db_session.merge(opp)
    db_session.merge(gw_past)
    db_session.merge(gw)
    db_session.flush()

    # 2. Players and Fixtures
    fixture_past = Fixture(
        fpl_id=8701,
        gameweek=87,
        home_team_fpl_id=881,
        away_team_fpl_id=882,
        kickoff_time=now - timedelta(days=5, hours=2),
        finished=True,
    )
    fixture = Fixture(
        fpl_id=8801,
        gameweek=88,
        home_team_fpl_id=881,
        away_team_fpl_id=882,
        kickoff_time=now + timedelta(days=2, hours=2),
        finished=False,
    )
    player = Player(
        fpl_id=88001,
        web_name="Saka Test",
        first_name="Bukayo",
        second_name="Saka",
        position="MID",
        team_fpl_id=881,
        status="a",
        now_cost=100,
    )
    db_session.merge(fixture_past)
    db_session.merge(fixture)
    db_session.merge(player)
    db_session.flush()

    # 3. Match stats (1 goal across 180 mins -> xG_90 = 0.5 -> within bounds)
    pfs = PlayerFixtureStat(
        player_fpl_id=88001,
        fixture_fpl_id=8701,
        gameweek=87,
        was_starter=True,
        minutes=180,
        total_points=8,
        goals_scored=1,
        assists=0,
        source_fetched_at=now - timedelta(days=4),
    )
    db_session.merge(pfs)
    db_session.commit()

    # Run projections for gameweek 88
    res = run_projections_for_gameweek(db_session, target_gameweek=88)
    assert res["status"] == "OK"

    # Verify published_projections row
    pub = db_session.query(PublishedProjection).filter(PublishedProjection.gameweek == 88).first()
    assert pub is not None
    assert pub.bundle_json is not None
    bundle = pub.bundle_json

    assert bundle["gameweek"] == 88
    assert bundle["model_version"] == "xp-v1.5.0"
    assert "input_hash" in bundle
    assert "generated_at" in bundle
    assert len(bundle["players"]) == 1
    assert bundle["players"][0]["fpl_id"] == 88001
    assert len(bundle["players"][0]["fixtures"]) == 1
    assert bundle["players"][0]["fixtures"][0]["fixture_fpl_id"] == 8801
    assert bundle["players"][0]["fixtures"][0]["expected_points"] > 0.0


def test_get_projections_and_etag_304(client: TestClient, db_session: Session):
    """
    Verifies GET /api/v1/projections/{gw}:
    - Returns bundle with ETag and Cache-Control.
    - Returns 304 when matching If-None-Match header is sent.
    - Returns 404 when projections are not published.
    """
    now = datetime.now(UTC)
    # 1. 404 for unpublished gameweek
    resp_404 = client.get("/api/v1/projections/999")
    assert resp_404.status_code == 404

    # 2. Setup a published projection on GW 186
    gw = Gameweek(
        id=186,
        name="Gameweek 186",
        deadline_time=now + timedelta(days=2),
        finished=False,
        is_current=False,
        is_next=False,
    )
    db_session.merge(gw)
    db_session.commit()

    ensure_model_version(db_session)
    run_id = uuid.uuid4()
    p_run = ProjectionRun(
        id=run_id,
        gameweek=186,
        model_version="xp-v1.5.0",
        input_hash=uuid.uuid4().bytes + uuid.uuid4().bytes,
        inputs_as_of=now,
        status="OK",
    )
    db_session.merge(p_run)
    db_session.commit()

    bundle_data = {
        "gameweek": 186,
        "model_version": "xp-v1.5.0",
        "inputs_as_of": "2026-10-14T12:00:00Z",
        "generated_at": "2026-10-14T12:05:00Z",
        "players": [
            {
                "fpl_id": 8202,
                "fixtures": [
                    {"fixture_fpl_id": 8601, "expected_points": 5.4, "availability": 1.0, "expected_minutes": 85}
                ],
            }
        ],
    }
    pub = PublishedProjection(
        gameweek=186,
        run_id=run_id,
        bundle_json=bundle_data,
    )
    db_session.merge(pub)
    db_session.commit()

    # 3. GET projections bundle
    resp = client.get("/api/v1/projections/186")
    assert resp.status_code == 200
    assert "ETag" in resp.headers
    etag = resp.headers["ETag"]
    assert "public" in resp.headers.get("Cache-Control", "")
    assert resp.json()["gameweek"] == 186
    assert resp.json()["players"][0]["fpl_id"] == 8202

    # 4. Conditional GET with matching ETag -> 304 Not Modified
    resp_304 = client.get("/api/v1/projections/186", headers={"If-None-Match": etag})
    assert resp_304.status_code == 304
    assert resp_304.content == b""


def test_get_player_projection(client: TestClient, db_session: Session):
    """
    Verifies GET /api/v1/projections/{gw}/players/{fpl_id}:
    - Returns single player's projection details.
    - Returns 404 for missing player or missing gameweek.
    """
    now = datetime.now(UTC)
    gw = Gameweek(
        id=187,
        name="Gameweek 187",
        deadline_time=now + timedelta(days=2),
        finished=False,
        is_current=False,
        is_next=False,
    )
    db_session.merge(gw)
    db_session.commit()

    ensure_model_version(db_session)
    run_id = uuid.uuid4()
    p_run = ProjectionRun(
        id=run_id,
        gameweek=187,
        model_version="xp-v1.5.0",
        input_hash=uuid.uuid4().bytes + uuid.uuid4().bytes,
        inputs_as_of=now,
        status="OK",
    )
    db_session.merge(p_run)
    db_session.commit()

    bundle_data = {
        "gameweek": 187,
        "model_version": "xp-v1.5.0",
        "inputs_as_of": "2026-10-14T12:00:00Z",
        "generated_at": "2026-10-14T12:05:00Z",
        "players": [
            {
                "fpl_id": 8303,
                "fixtures": [{"fixture_fpl_id": 8701, "expected_points": 7.1, "availability": 1.0}],
            }
        ],
    }
    pub = PublishedProjection(gameweek=187, run_id=run_id, bundle_json=bundle_data)
    db_session.merge(pub)
    db_session.commit()

    # Success
    resp = client.get("/api/v1/projections/187/players/8303")
    assert resp.status_code == 200
    data = resp.json()
    assert data["fpl_id"] == 8303
    assert data["gameweek"] == 187
    assert data["fixtures"][0]["expected_points"] == 7.1

    # Not found player
    resp_miss = client.get("/api/v1/projections/187/players/9999")
    assert resp_miss.status_code == 404


def test_get_current_gameweek(client: TestClient, db_session: Session):
    """
    Verifies GET /api/v1/gameweeks/current returns current and next gameweeks.
    """
    now = datetime.now(UTC)
    # Ensure other gameweeks do not have current/next flags
    db_session.query(Gameweek).update({"is_current": False, "is_next": False})
    db_session.commit()

    gw1 = Gameweek(
        id=88,
        name="Gameweek 88",
        deadline_time=now + timedelta(hours=6),
        finished=False,
        is_current=True,
        is_next=False,
    )
    gw2 = Gameweek(
        id=89,
        name="Gameweek 89",
        deadline_time=now + timedelta(days=7),
        finished=False,
        is_current=False,
        is_next=True,
    )
    db_session.merge(gw1)
    db_session.merge(gw2)
    db_session.commit()

    resp = client.get("/api/v1/gameweeks/current")
    assert resp.status_code == 200
    data = resp.json()
    assert data["current"]["id"] == 88
    assert data["current"]["is_current"] is True
    assert data["next"]["id"] == 89
    assert data["next"]["is_next"] is True


def test_get_fixtures(client: TestClient, db_session: Session):
    """
    Verifies GET /api/v1/fixtures and GET /api/v1/fixtures?gw=.
    """
    now = datetime.now(UTC)
    gw1 = Gameweek(id=930, name="GW 930", deadline_time=now + timedelta(days=1), finished=False)
    gw2 = Gameweek(id=931, name="GW 931", deadline_time=now + timedelta(days=8), finished=False)
    t1 = Team(fpl_id=910, name="City Test", short_name="MCT", strength_attack_home=1300, strength_attack_away=1300, strength_defence_home=1200, strength_defence_away=1200)
    t2 = Team(fpl_id=911, name="United Test", short_name="MNT", strength_attack_home=1100, strength_attack_away=1100, strength_defence_home=1100, strength_defence_away=1100)

    db_session.merge(gw1)
    db_session.merge(gw2)
    db_session.merge(t1)
    db_session.merge(t2)
    db_session.flush()

    f1 = Fixture(fpl_id=9801, gameweek=930, home_team_fpl_id=910, away_team_fpl_id=911, kickoff_time=now + timedelta(days=1), finished=False)
    f2 = Fixture(fpl_id=9802, gameweek=931, home_team_fpl_id=911, away_team_fpl_id=910, kickoff_time=now + timedelta(days=8), finished=False)

    db_session.merge(f1)
    db_session.merge(f2)
    db_session.commit()

    # Filtered by gw=930
    resp = client.get("/api/v1/fixtures?gw=930")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 1
    assert data[0]["fpl_id"] == 9801
    assert data[0]["home_team_fpl_id"] == 910


def test_search_players(client: TestClient, db_session: Session):
    """
    Verifies GET /api/v1/players/search?q= requires auth and returns matching players.
    """
    team = Team(
        fpl_id=950,
        name="Search Team",
        short_name="STM",
        strength_attack_home=1100,
        strength_attack_away=1100,
        strength_defence_home=1100,
        strength_defence_away=1100,
    )
    db_session.merge(team)
    db_session.flush()

    p = Player(
        fpl_id=9401,
        web_name="ErlingSearch",
        first_name="Erling",
        second_name="HaalandSearch",
        position="FWD",
        team_fpl_id=950,
        status="a",
        now_cost=150,
    )
    db_session.merge(p)
    db_session.commit()

    # 1. Unauthenticated -> 401
    resp_unauth = client.get("/api/v1/players/search?q=ErlingSearch")
    assert resp_unauth.status_code == 401

    # 2. Authenticated user
    user_id = uuid.uuid4()
    u = User(
        id=user_id,
        email=f"test_search_{user_id.hex[:6]}@example.com",
        fpl_team_id=random.randint(1000000, 9999999),
        status="active",
        email_verified_at=datetime.now(UTC),
    )
    db_session.merge(u)
    db_session.commit()
    token = create_access_token(u)

    resp_auth = client.get(
        "/api/v1/players/search?q=ErlingSearch",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp_auth.status_code == 200
    results = resp_auth.json()
    assert len(results) == 1
    assert results[0]["web_name"] == "ErlingSearch"
    assert results[0]["fpl_id"] == 9401


def test_cleanup_job_retention_rules(db_session: Session):
    """
    Sprint 6 Verification items:
    - A deliberately deleted unverified account is removed by the cleanup job within one run.
    - A deletion requested four days ago is removed by the cleanup job. A deletion requested two days ago is not.
    - Expired email codes, refresh tokens, and cache entries are removed.
    """
    now = datetime.now(UTC)

    old_unv_id = uuid.uuid4()
    young_unv_id = uuid.uuid4()
    del_4d_id = uuid.uuid4()
    del_2d_id = uuid.uuid4()

    # 1. Users first (unique random fpl_team_id)
    old_unverified = User(
        id=old_unv_id,
        email=f"old_unv_{old_unv_id.hex[:6]}@example.com",
        fpl_team_id=random.randint(10000000, 20000000),
        status="unverified",
        created_at=now - timedelta(days=4),
    )
    young_unverified = User(
        id=young_unv_id,
        email=f"young_unv_{young_unv_id.hex[:6]}@example.com",
        fpl_team_id=random.randint(20000001, 30000000),
        status="unverified",
        created_at=now - timedelta(days=2),
    )
    deleted_4_days = User(
        id=del_4d_id,
        email=f"del_4d_{del_4d_id.hex[:6]}@example.com",
        fpl_team_id=random.randint(30000001, 40000000),
        status="pending_deletion",
        deletion_requested_at=now - timedelta(days=4),
    )
    deleted_2_days = User(
        id=del_2d_id,
        email=f"del_2d_{del_2d_id.hex[:6]}@example.com",
        fpl_team_id=random.randint(40000001, 50000000),
        status="pending_deletion",
        deletion_requested_at=now - timedelta(days=2),
    )

    db_session.add_all([old_unverified, young_unverified, deleted_4_days, deleted_2_days])
    db_session.commit()

    # 2. Codes, tokens, cache
    exp_code_hash = uuid.uuid4().bytes
    val_code_hash = uuid.uuid4().bytes
    exp_token_hash = uuid.uuid4().bytes
    val_token_hash = uuid.uuid4().bytes

    expired_code = EmailCode(
        user_id=young_unv_id,
        purpose="verify_email",
        code_hash=exp_code_hash,
        expires_at=now - timedelta(minutes=10),
    )
    valid_code = EmailCode(
        user_id=young_unv_id,
        purpose="verify_email",
        code_hash=val_code_hash,
        expires_at=now + timedelta(minutes=10),
    )
    expired_token = RefreshToken(
        user_id=young_unv_id,
        family_id=uuid.uuid4(),
        token_hash=exp_token_hash,
        expires_at=now - timedelta(days=1),
    )
    valid_token = RefreshToken(
        user_id=young_unv_id,
        family_id=uuid.uuid4(),
        token_hash=val_token_hash,
        expires_at=now + timedelta(days=10),
    )
    exp_key = f"expired_key_{uuid.uuid4().hex[:6]}"
    val_key = f"valid_key_{uuid.uuid4().hex[:6]}"
    expired_cache = CacheEntry(
        cache_key=exp_key,
        value={"data": 1},
        expires_at=now - timedelta(minutes=5),
    )
    valid_cache = CacheEntry(
        cache_key=val_key,
        value={"data": 2},
        expires_at=now + timedelta(minutes=5),
    )

    db_session.add_all([
        expired_code, valid_code, expired_token, valid_token,
        expired_cache, valid_cache,
    ])
    db_session.commit()

    # Run cleanup job
    stats = run_full_cleanup(db_session, grace_days=3)
    assert stats["unverified_deleted"] >= 1
    assert stats["pending_deletion_deleted"] >= 1
    assert stats["codes_deleted"] >= 1
    assert stats["tokens_deleted"] >= 1
    assert stats["cache_deleted"] >= 1

    # Verify accounts state
    assert db_session.query(User).filter(User.id == old_unv_id).first() is None
    assert db_session.query(User).filter(User.id == young_unv_id).first() is not None
    assert db_session.query(User).filter(User.id == del_4d_id).first() is None
    assert db_session.query(User).filter(User.id == del_2d_id).first() is not None

    # Verify tokens, codes, and cache state
    assert db_session.query(EmailCode).filter(EmailCode.code_hash == exp_code_hash).first() is None
    assert db_session.query(EmailCode).filter(EmailCode.code_hash == val_code_hash).first() is not None
    assert db_session.query(RefreshToken).filter(RefreshToken.token_hash == exp_token_hash).first() is None
    assert db_session.query(RefreshToken).filter(RefreshToken.token_hash == val_token_hash).first() is not None
    assert db_session.query(CacheEntry).filter(CacheEntry.cache_key == exp_key).first() is None
    assert db_session.query(CacheEntry).filter(CacheEntry.cache_key == val_key).first() is not None


def test_failed_projection_job_records_failed_and_does_not_publish(db_session: Session):
    """
    Verification: A failed job marks its ingestion_runs row as FAILED and does not publish a bundle.
    """
    # Trigger run_projection_job on non-existent gameweek
    try:
        run_projection_job(db_session, gameweek=9999)
    except Exception:  # noqa: BLE001
        pass

    # Check ingestion_runs
    failed_run = (
        db_session.query(IngestionRun)
        .filter(IngestionRun.job_name == "project")
        .order_by(IngestionRun.id.desc())
        .first()
    )
    assert failed_run is not None
    assert failed_run.status == "FAILED"
    assert failed_run.error_summary is not None

    # Check that no bundle was published for GW 9999
    pub = db_session.query(PublishedProjection).filter(PublishedProjection.gameweek == 9999).first()
    assert pub is None


def test_health_endpoint_reports_last_ingestion(client: TestClient, db_session: Session):
    """
    Verification: The health endpoint reports the last ingestion time.
    """
    now = datetime.now(UTC)
    run = IngestionRun(
        job_name="bootstrap",
        started_at=now - timedelta(minutes=5),
        finished_at=now - timedelta(minutes=4),
        status="OK",
        rows_written=50,
    )
    db_session.add(run)
    db_session.commit()

    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["database"] == "connected"
    assert data["last_ingestion_at"] is not None

    # Also test /api/v1/health
    resp_v1 = client.get("/api/v1/health")
    assert resp_v1.status_code == 200
    assert resp_v1.json()["last_ingestion_at"] is not None
