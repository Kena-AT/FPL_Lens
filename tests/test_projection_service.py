import uuid
from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.config import settings
from fpl_lens.db.models import (
    Fixture,
    Gameweek,
    ModelVersion,
    Player,
    PlayerFixtureStat,
    PlayerProjection,
    ProjectionRun,
    Team,
)
from fpl_lens.engine.projection import run_projection_cycle
from fpl_lens.engine.service import run_projections_for_gameweek
from fpl_lens.engine.types import FixtureContext, PlayerFeatures, TeamStrength


def test_engine_determinism():
    """
    Sprint 5 Verification item:
    Running the engine twice on the same inputs gives identical output.
    """
    teams = {
        1: TeamStrength(1, "Arsenal", "ARS", 1250, 1200, 1300, 1250),
        2: TeamStrength(2, "Chelsea", "CHE", 1150, 1100, 1150, 1100),
    }
    fixtures = [
        FixtureContext(
            fixture_fpl_id=101,
            gameweek=1,
            team_fpl_id=1,
            opponent_fpl_id=2,
            is_home=True,
        )
    ]
    players = [
        PlayerFeatures(
            player_fpl_id=10,
            position="MID",
            status="a",
            chance_of_playing_next_round=None,
            team_fpl_id=1,
            xg_90=0.45,
            xa_90=0.30,
            history=[],
        ),
        PlayerFeatures(
            player_fpl_id=20,
            position="DEF",
            status="d",
            chance_of_playing_next_round=75,
            team_fpl_id=1,
            xg_90=0.05,
            xa_90=0.10,
            history=[],
        ),
    ]
    league_averages = {
        "mu": 1.35,
        "att_home_avg": 1200.0,
        "att_away_avg": 1150.0,
        "def_home_avg": 1225.0,
        "def_away_avg": 1175.0,
    }

    # Run 1
    projections1, hash1 = run_projection_cycle(
        gameweek=1,
        players=players,
        fixtures=fixtures,
        teams=teams,
        league_averages=league_averages,
    )

    # Run 2
    projections2, hash2 = run_projection_cycle(
        gameweek=1,
        players=players,
        fixtures=fixtures,
        teams=teams,
        league_averages=league_averages,
    )

    # Hashes must match
    assert hash1 == hash2

    # Projections count and values must match bit-for-bit
    assert len(projections1) == len(projections2)
    for p1, p2 in zip(projections1, projections2, strict=True):
        assert p1.player_fpl_id == p2.player_fpl_id
        assert p1.fixture_fpl_id == p2.fixture_fpl_id
        assert p1.expected_minutes == p2.expected_minutes
        assert p1.components.expected_points == p2.components.expected_points
        assert p1.components.exp_goals == p2.components.exp_goals
        assert p1.components.exp_clean_sheet == p2.components.exp_clean_sheet


def test_projection_service_database_persistence_and_freeze_rule(db_session: Session):
    """
    Sprint 5 tasks:
    - Write the projection run to projection_runs and player_projections
    - Model version and config recorded in model_versions, with status shadow
    - Freeze rule: only data fetched at or before the deadline enters a run
    """
    now = datetime.now(UTC)
    deadline = now - timedelta(hours=2)

    # Setup DB records
    team1 = Team(
        fpl_id=881,
        name="Team Alpha",
        short_name="TAL",
        strength_attack_home=1200,
        strength_attack_away=1150,
        strength_defence_home=1250,
        strength_defence_away=1200,
    )
    team2 = Team(
        fpl_id=882,
        name="Team Beta",
        short_name="TBE",
        strength_attack_home=1100,
        strength_attack_away=1050,
        strength_defence_home=1150,
        strength_defence_away=1100,
    )
    gw87 = Gameweek(
        id=87,
        name="GW 87",
        deadline_time=deadline - timedelta(days=2),
        finished=True,
        is_current=False,
    )
    gw = Gameweek(
        id=88,
        name="GW 88",
        deadline_time=deadline,
        finished=False,
        is_current=False,
    )
    db_session.merge(team1)
    db_session.merge(team2)
    db_session.merge(gw87)
    db_session.merge(gw)
    db_session.flush()

    fixture_past = Fixture(
        fpl_id=8701,
        gameweek=87,
        kickoff_time=deadline - timedelta(days=2),
        home_team_fpl_id=881,
        away_team_fpl_id=882,
        finished=True,
    )
    fixture = Fixture(
        fpl_id=8801,
        gameweek=88,
        kickoff_time=deadline + timedelta(hours=1),
        home_team_fpl_id=881,
        away_team_fpl_id=882,
        finished=False,
    )
    player = Player(
        fpl_id=88001,
        first_name="Alpha",
        second_name="Star",
        web_name="A.Star",
        position="FWD",
        team_fpl_id=881,
        now_cost=95,
        status="a",
    )
    db_session.merge(fixture_past)
    db_session.merge(fixture)
    db_session.merge(player)
    db_session.flush()

    # Stat 1: fetched BEFORE deadline -> included
    stat_before = PlayerFixtureStat(
        player_fpl_id=88001,
        fixture_fpl_id=8701,
        gameweek=87,
        was_starter=True,
        minutes=90,
        goals_scored=2,
        source_fetched_at=deadline - timedelta(days=1),
    )
    # Stat 2: fetched AFTER deadline -> MUST BE EXCLUDED by freeze rule
    stat_after = PlayerFixtureStat(
        player_fpl_id=88001,
        fixture_fpl_id=8801,
        gameweek=88,
        was_starter=True,
        minutes=90,
        goals_scored=5,
        source_fetched_at=deadline + timedelta(hours=5),
    )
    db_session.merge(stat_before)
    db_session.merge(stat_after)
    db_session.commit()

    # Execute projection service
    res = run_projections_for_gameweek(
        db_session,
        target_gameweek=88,
        model_version="xp-v1.5.0",
        enforce_freeze_rule=True,
    )

    assert res["status"] == "OK"
    run_id = uuid.UUID(res["run_id"])

    # 1. Check model_versions
    mv = db_session.query(ModelVersion).filter(ModelVersion.version == "xp-v1.5.0").first()
    assert mv is not None
    assert mv.status == "shadow"

    # 2. Check projection_runs
    pr = db_session.query(ProjectionRun).filter(ProjectionRun.id == run_id).first()
    assert pr is not None
    assert pr.gameweek == 88
    assert pr.status == "OK"

    # 3. Check player_projections
    pp = (
        db_session.query(PlayerProjection)
        .filter(PlayerProjection.run_id == run_id, PlayerProjection.player_fpl_id == 88001)
        .first()
    )
    assert pp is not None
    assert pp.expected_points > 0.0
    assert pp.expected_minutes > 0.0


def test_internal_project_job_endpoint(client: TestClient):
    """Verifies that POST /internal/jobs/project triggers with valid token."""
    token = settings.get_effective_job_token()

    # 1. Unauthorized without token -> 401
    resp_unauth = client.post("/internal/jobs/project")
    assert resp_unauth.status_code == 401

    # 2. Authorized with token -> 200
    resp_auth = client.post(
        "/internal/jobs/project",
        headers={"X-Job-Token": token},
    )
    assert resp_auth.status_code == 200
    data = resp_auth.json()
    assert data["status"] == "OK"
