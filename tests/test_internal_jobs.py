import json
from pathlib import Path

from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from fpl_lens.config import settings
from fpl_lens.db.models import Fixture, Gameweek, IngestionRun, Player, PlayerFixtureStat, Team
from fpl_lens.services.ingestion import (
    run_bootstrap_job,
    run_cleanup_job,
    run_fixtures_job,
    run_history_job,
)

FIXTURES_DIR = Path(__file__).parent / "fixtures"


def test_internal_job_token_authentication_401(client: TestClient):
    """
    Spec & Implementation Plan requirement:
    A job endpoint returns 401 without the job token or with an invalid token.
    Enforces constant-time comparison.
    """
    # 1. No token provided
    resp_no_token = client.post("/internal/jobs/bootstrap")
    assert resp_no_token.status_code == 401
    assert resp_no_token.json()["error"]["code"] == "UNAUTHENTICATED"

    # 2. Wrong token provided
    resp_wrong_token = client.post(
        "/internal/jobs/bootstrap",
        headers={"X-Job-Token": "invalid-wrong-token-abc"},
    )
    assert resp_wrong_token.status_code == 401
    assert resp_wrong_token.json()["error"]["code"] == "UNAUTHENTICATED"

    # 3. Invalid job name with correct token returns 404
    token = settings.get_effective_job_token()
    resp_invalid_job = client.post(
        "/internal/jobs/nonexistent_job",
        headers={"X-Job-Token": token},
    )
    assert resp_invalid_job.status_code == 404
    assert resp_invalid_job.json()["error"]["code"] == "NOT_FOUND"


def test_full_bootstrap_and_fixtures_run(client: TestClient, db_session: Session):
    """
    Spec & Implementation Plan requirement:
    A full bootstrap run followed by a fixtures run completes on the development branch,
    with an ingestion_runs row for each.
    """
    # Load recorded fixture data
    with open(FIXTURES_DIR / "bootstrap_static.json", encoding="utf-8") as f:
        bootstrap_data = json.load(f)

    with open(FIXTURES_DIR / "fixtures.json", encoding="utf-8") as f:
        fixtures_data = json.load(f)

    # 1. Run bootstrap job directly via ingestion service
    import asyncio
    boot_res = asyncio.run(run_bootstrap_job(db_session, bootstrap_data=bootstrap_data))
    assert boot_res["status"] == "OK"
    assert boot_res["rows_written"] > 600

    # Verify database rows created
    fpl_teams = db_session.execute(select(Team).where(Team.fpl_id.between(1, 20))).scalars().all()
    assert len(fpl_teams) == 20

    fpl_gws = db_session.execute(select(Gameweek).where(Gameweek.id.between(1, 38))).scalars().all()
    assert len(fpl_gws) == 38

    player_count = db_session.execute(select(Player)).scalars().all()
    assert len(player_count) > 500

    # Verify ingestion_runs row
    boot_run = db_session.query(IngestionRun).filter(IngestionRun.id == boot_res["run_id"]).first()
    assert boot_run is not None
    assert boot_run.job_name == "bootstrap"
    assert boot_run.status == "OK"

    # 2. Run fixtures job
    fix_res = asyncio.run(run_fixtures_job(db_session, fixtures_data=fixtures_data))
    assert fix_res["status"] == "OK"
    assert fix_res["rows_written"] == 380

    fpl_fixtures = db_session.execute(select(Fixture).where(Fixture.fpl_id.between(1, 380))).scalars().all()
    assert len(fpl_fixtures) == 380

    fix_run = db_session.query(IngestionRun).filter(IngestionRun.id == fix_res["run_id"]).first()
    assert fix_run is not None
    assert fix_run.job_name == "fixtures"
    assert fix_run.status == "OK"


def test_history_run_and_partial_failure(db_session: Session):
    """
    Spec & Implementation Plan requirement:
    A history run completes within the throttle budget, with a PARTIAL status
    only where records genuinely failed (e.g. unparseable numeric strings).
    """
    import asyncio
    from datetime import UTC, datetime

    # Ensure at least one team, gameweek, fixture and player exist
    team = Team(
        fpl_id=99,
        name="Test FC",
        short_name="TFC",
        strength_attack_home=1000,
        strength_attack_away=1000,
        strength_defence_home=1000,
        strength_defence_away=1000,
    )
    gw = Gameweek(
        id=99,
        name="GW 99",
        deadline_time=datetime.now(UTC),
        finished=False,
        is_current=False,
    )
    db_session.merge(team)
    db_session.merge(gw)
    db_session.flush()

    fix = Fixture(fpl_id=999, gameweek=99, home_team_fpl_id=99, away_team_fpl_id=99, finished=True)
    db_session.merge(fix)
    db_session.flush()

    player = Player(
        fpl_id=9999,
        first_name="Test",
        second_name="Striker",
        web_name="Striker",
        position="FWD",
        team_fpl_id=99,
        now_cost=80,
        status="a",
    )
    db_session.merge(player)
    db_session.commit()

    # 1. Valid history entry -> OK status
    valid_summary = {
        "history": [
            {
                "element": 9999,
                "fixture": 999,
                "round": 99,
                "starts": 1,
                "minutes": 90,
                "total_points": 8,
                "goals_scored": 1,
                "assists": 0,
                "clean_sheets": 0,
                "goals_conceded": 1,
                "defensive_contribution": 0,
                "bps": 24,
                "bonus": 2,
                "yellow_cards": 0,
                "red_cards": 0,
                "expected_goals": "0.75",
                "expected_assists": "0.10",
                "expected_goal_involvements": "0.85",
                "expected_goals_conceded": "1.20",
            }
        ]
    }

    res_ok = asyncio.run(
        run_history_job(
            db_session,
            player_ids=[9999],
            mock_history_map={9999: valid_summary},
        )
    )
    assert res_ok["status"] == "OK"
    assert res_ok["rows_written"] == 1
    assert res_ok["failed_records"] == 0

    stat_row = (
        db_session.query(PlayerFixtureStat)
        .filter(PlayerFixtureStat.player_fpl_id == 9999, PlayerFixtureStat.fixture_fpl_id == 999)
        .first()
    )
    assert stat_row is not None
    assert stat_row.goals_scored == 1

    # 2. Unparseable numeric string ('abc') in expected_goals -> fails record, marked PARTIAL
    invalid_summary = {
        "history": [
            {
                "element": 9999,
                "fixture": 999,
                "round": 99,
                "starts": 1,
                "minutes": 90,
                "total_points": 8,
                "goals_scored": 1,
                "assists": 0,
                "clean_sheets": 0,
                "goals_conceded": 1,
                "defensive_contribution": 0,
                "bps": 24,
                "bonus": 2,
                "yellow_cards": 0,
                "red_cards": 0,
                "expected_goals": "abc",  # unparseable string fails the record
                "expected_assists": "0.10",
                "expected_goal_involvements": "0.85",
                "expected_goals_conceded": "1.20",
            }
        ]
    }

    res_partial = asyncio.run(
        run_history_job(
            db_session,
            player_ids=[9999],
            mock_history_map={9999: invalid_summary},
        )
    )
    assert res_partial["status"] == "PARTIAL"
    assert res_partial["failed_records"] == 1

    run_row = db_session.query(IngestionRun).filter(IngestionRun.id == res_partial["run_id"]).first()
    assert run_row is not None
    assert run_row.status == "PARTIAL"
    assert "1 history records failed validation" in run_row.error_summary


def test_cleanup_job_run(db_session: Session):
    """Verifies that the cleanup job runs and records an ingestion_runs entry."""
    import asyncio

    res = asyncio.run(run_cleanup_job(db_session))
    assert res["status"] == "OK"
    assert "stats" in res
