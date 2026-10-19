"""
Database service and persistence layer for the Layer 1 projection engine.
Enforces the freeze rule, input hashing, and writes to projection_runs and player_projections.
"""

import uuid
from datetime import UTC, datetime
from typing import Any, cast

from sqlalchemy import ColumnElement, func, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.orm import Session

from fpl_lens.db.models import (
    Fixture,
    Gameweek,
    IngestionRun,
    ModelVersion,
    Player,
    PlayerFixtureStat,
    PlayerProjection,
    ProjectionRun,
    PublishedProjection,
    Team,
)
from fpl_lens.engine.intensities import compute_league_averages
from fpl_lens.engine.projection import run_projection_cycle
from fpl_lens.engine.types import (
    FixtureContext,
    FixtureProjection,
    PlayerFeatures,
    PlayerMatchHistory,
    TeamStrength,
)
from fpl_lens.logging import logger

DEFAULT_MODEL_VERSION = "xp-v1.5.0"


def ensure_model_version(
    db: Session,
    version: str = DEFAULT_MODEL_VERSION,
    config: dict | None = None,
    status: str = "shadow",
    notes: str = "Layer 1 projection engine (Spec v1.5)",
) -> ModelVersion:
    """Ensures that the model version is registered in model_versions table."""
    mv = db.query(ModelVersion).filter(ModelVersion.version == version).first()
    if not mv:
        cfg = config or {
            "window_size": 5,
            "shrinkage_weight": 2.0,
            "tail_tolerance": 1e-6,
            "scoring_rules": "official-2024-25",
        }
        mv = ModelVersion(
            version=version,
            config=cfg,
            status=status,
            notes=notes,
        )
        db.add(mv)
        db.flush()
    return mv


def run_projections_for_gameweek(
    db: Session,
    target_gameweek: int,
    model_version: str = DEFAULT_MODEL_VERSION,
    enforce_freeze_rule: bool = True,
) -> dict:
    """
    Executes a projection run for target_gameweek.
    Enforces freeze rule: only data fetched at or before the gameweek deadline enters the run.
    Writes to projection_runs and player_projections.
    """
    logger.info("Starting projection run for GW %d with model %s", target_gameweek, model_version)

    # 1. Get gameweek deadline
    gw = db.query(Gameweek).filter(Gameweek.id == target_gameweek).first()
    if not gw:
        raise ValueError(f"Gameweek {target_gameweek} not found")

    deadline = gw.deadline_time
    as_of = deadline if (enforce_freeze_rule and deadline) else datetime.now(UTC)

    # 2. Ensure model version exists
    ensure_model_version(db, version=model_version)

    # 3. Load teams
    db_teams = db.query(Team).all()
    teams_map: dict[int, TeamStrength] = {
        int(t.fpl_id): TeamStrength(
            fpl_id=int(t.fpl_id),
            name=str(t.name or ""),
            short_name=str(t.short_name or ""),
            strength_attack_home=int(t.strength_attack_home or 1000),
            strength_attack_away=int(t.strength_attack_away or 1000),
            strength_defence_home=int(t.strength_defence_home or 1000),
            strength_defence_away=int(t.strength_defence_away or 1000),
        )
        for t in db_teams
        if t.fpl_id is not None
    }

    # 4. Load finished matches prior to deadline to compute league average mu
    finished_query: Any = select(
        func.count(PlayerFixtureStat.fixture_fpl_id.distinct()),
        func.sum(PlayerFixtureStat.goals_scored),
    ).where(cast(ColumnElement[bool], PlayerFixtureStat.source_fetched_at <= as_of))
    matches_count, total_goals = db.execute(finished_query).first() or (0, 0)
    matches_count = matches_count or 0
    total_goals = total_goals or 0

    league_averages = compute_league_averages(
        list(teams_map.values()),
        total_goals=int(total_goals),
        matches_played=int(matches_count),
    )

    # 5. Load upcoming fixtures for target gameweek
    db_fixtures = db.query(Fixture).filter(Fixture.gameweek == target_gameweek).all()
    fixtures_context: list[FixtureContext] = []
    for f in db_fixtures:
        if f.fpl_id is None or f.home_team_fpl_id is None or f.away_team_fpl_id is None:
            continue
        # Home fixture context
        fixtures_context.append(
            FixtureContext(
                fixture_fpl_id=int(f.fpl_id),
                gameweek=target_gameweek,
                team_fpl_id=int(f.home_team_fpl_id),
                opponent_fpl_id=int(f.away_team_fpl_id),
                is_home=True,
                kickoff_time=cast(datetime | None, f.kickoff_time),
            )
        )
        # Away fixture context
        fixtures_context.append(
            FixtureContext(
                fixture_fpl_id=int(f.fpl_id),
                gameweek=target_gameweek,
                team_fpl_id=int(f.away_team_fpl_id),
                opponent_fpl_id=int(f.home_team_fpl_id),
                is_home=False,
                kickoff_time=cast(datetime | None, f.kickoff_time),
            )
        )

    # 6. Load players and their historical stats up to freeze deadline
    db_players = db.query(Player).all()

    # Query all historical stats up to as_of
    stats_query = (
        select(PlayerFixtureStat)
        .where(PlayerFixtureStat.source_fetched_at <= as_of)
        .order_by(PlayerFixtureStat.gameweek.asc())
    )
    all_stats = db.execute(stats_query).scalars().all()

    player_stats_map: dict[int, list[PlayerMatchHistory]] = {}
    for st in all_stats:
        if st.player_fpl_id is None:
            continue
        player_stats_map.setdefault(int(st.player_fpl_id), []).append(
            PlayerMatchHistory(
                gameweek=int(st.gameweek or 0),
                was_starter=bool(st.was_starter),
                minutes=int(st.minutes or 0),
                goals_scored=int(st.goals_scored or 0),
                assists=int(st.assists or 0),
                clean_sheets=int(st.clean_sheets or 0),
                goals_conceded=int(st.goals_conceded or 0),
                defensive_contributions=int(st.defensive_contributions or 0),
                bps=int(st.bps or 0),
                bonus=int(st.bonus or 0),
                yellow_cards=int(st.yellow_cards or 0),
                red_cards=int(st.red_cards or 0),
                source_fetched_at=cast(datetime | None, st.source_fetched_at),
            )
        )

    players_features: list[PlayerFeatures] = []
    for p in db_players:
        if p.fpl_id is None:
            continue
        p_hist = player_stats_map.get(int(p.fpl_id), [])
        total_mins = sum(h.minutes for h in p_hist)
        pos_str = str(p.position or "")
        if total_mins >= 90:
            xg_90 = (sum(h.goals_scored for h in p_hist) / total_mins) * 90.0
            xa_90 = (sum(h.assists for h in p_hist) / total_mins) * 90.0
        else:
            # Baseline positional defaults [PLACEHOLDER]
            pos_xg_defaults = {"FWD": 0.35, "MID": 0.18, "DEF": 0.05, "GK": 0.0}
            pos_xa_defaults = {"FWD": 0.15, "MID": 0.18, "DEF": 0.08, "GK": 0.01}
            xg_90 = pos_xg_defaults.get(pos_str, 0.10)
            xa_90 = pos_xa_defaults.get(pos_str, 0.10)

        players_features.append(
            PlayerFeatures(
                player_fpl_id=int(p.fpl_id),
                position=pos_str,
                status=str(p.status or "a"),
                chance_of_playing_next_round=int(p.chance_of_playing_next_round)
                if p.chance_of_playing_next_round is not None
                else None,
                team_fpl_id=int(p.team_fpl_id or 0),
                xg_90=xg_90,
                xa_90=xa_90,
                history=p_hist,
            )
        )

    # 7. Run projection cycle
    projections, input_hash = run_projection_cycle(
        gameweek=target_gameweek,
        players=players_features,
        fixtures=fixtures_context,
        teams=teams_map,
        league_averages=league_averages,
    )

    # 8. Check if an identical run exists
    existing_run = (
        db.query(ProjectionRun)
        .filter(
            ProjectionRun.gameweek == target_gameweek,
            ProjectionRun.model_version == model_version,
            ProjectionRun.input_hash == input_hash,
        )
        .first()
    )

    if existing_run:
        logger.info(
            "Identical projection run already exists for GW %d (run_id: %s)",
            target_gameweek,
            existing_run.id,
        )
        # Ensure published_projections is populated even on reused run
        existing_pub = (
            db.query(PublishedProjection)
            .filter(PublishedProjection.gameweek == target_gameweek)
            .first()
        )
        if not existing_pub:
            _publish_bundle(
                db=db,
                gameweek=target_gameweek,
                run_id=cast(uuid.UUID, existing_run.id),
                model_version=model_version,
                input_hash=input_hash,
                inputs_as_of=cast(datetime, as_of),
                projections=projections,
            )

        return {
            "status": "OK",
            "run_id": str(existing_run.id),
            "gameweek": target_gameweek,
            "projections_count": len(projections),
            "input_hash": input_hash.hex(),
            "reused": True,
        }

    # 9. Create projection_runs entry
    run_id = uuid.uuid4()
    proj_run = ProjectionRun(
        gameweek=target_gameweek,
        model_version=model_version,
        input_hash=input_hash,
        inputs_as_of=as_of,
        status="OK",
    )
    proj_run.id = run_id  # type: ignore[assignment]
    db.add(proj_run)
    db.flush()

    # 10. Batch insert player_projections
    if projections:
        rows_to_insert = [
            {
                "run_id": run_id,
                "player_fpl_id": p.player_fpl_id,
                "fixture_fpl_id": p.fixture_fpl_id,
                "availability": round(p.availability, 3),
                "p_start": round(p.p_start, 3),
                "p_sub": round(p.p_sub, 3),
                "p_60_plus_given_start": round(p.p_60_plus_given_start, 3),
                "expected_minutes": round(p.expected_minutes, 2),
                "exp_goals": round(p.components.exp_goals, 3),
                "exp_assists": round(p.components.exp_assists, 3),
                "exp_appearance": round(p.components.exp_appearance, 3),
                "exp_clean_sheet": round(p.components.exp_clean_sheet, 3),
                "exp_goals_conceded": round(p.components.exp_goals_conceded, 3),
                "exp_dc": round(p.components.exp_dc, 3),
                "exp_bonus": round(p.components.exp_bonus, 3),
                "exp_card_penalty": round(p.components.exp_card_penalty, 3),
                "expected_points": round(p.components.expected_points, 3),
            }
            for p in projections
        ]

        stmt = pg_insert(PlayerProjection).values(rows_to_insert)
        stmt = stmt.on_conflict_do_update(
            index_elements=["run_id", "player_fpl_id", "fixture_fpl_id"],
            set_={
                "expected_points": stmt.excluded.expected_points,
                "expected_minutes": stmt.excluded.expected_minutes,
            },
        )
        db.execute(stmt)

    # 11. Publish bundle to published_projections
    _publish_bundle(
        db=db,
        gameweek=target_gameweek,
        run_id=run_id,
        model_version=model_version,
        input_hash=input_hash,
        inputs_as_of=cast(datetime, as_of),
        projections=projections,
    )

    db.commit()
    logger.info(
        "Projection run %s committed and published with %d projections", run_id, len(projections)
    )

    return {
        "status": "OK",
        "run_id": str(run_id),
        "gameweek": target_gameweek,
        "projections_count": len(projections),
        "input_hash": input_hash.hex(),
        "reused": False,
    }


def _publish_bundle(
    db: Session,
    gameweek: int,
    run_id: uuid.UUID,
    model_version: str,
    input_hash: bytes,
    inputs_as_of: datetime,
    projections: list[FixtureProjection],
) -> None:
    """Generates the JSON document bundle and persists to published_projections table."""
    players_dict: dict[int, list[dict[str, Any]]] = {}
    for p in projections:
        players_dict.setdefault(p.player_fpl_id, []).append(
            {
                "fixture_fpl_id": p.fixture_fpl_id,
                "expected_points": round(float(p.components.expected_points), 2),
                "availability": round(float(p.availability), 2),
                "p_start": round(float(p.p_start), 2),
                "p_sub": round(float(p.p_sub), 2),
                "p_60_plus_given_start": round(float(p.p_60_plus_given_start), 2),
                "expected_minutes": round(float(p.expected_minutes), 1),
                "exp_goals": round(float(p.components.exp_goals), 3),
                "exp_assists": round(float(p.components.exp_assists), 3),
                "exp_appearance": round(float(p.components.exp_appearance), 3),
                "exp_clean_sheet": round(float(p.components.exp_clean_sheet), 3),
                "exp_goals_conceded": round(float(p.components.exp_goals_conceded), 3),
                "exp_dc": round(float(p.components.exp_dc), 3),
                "exp_bonus": round(float(p.components.exp_bonus), 3),
                "exp_card_penalty": round(float(p.components.exp_card_penalty), 3),
            }
        )

    players_list = [
        {"fpl_id": fpl_id, "fixtures": fixtures}
        for fpl_id, fixtures in sorted(players_dict.items())
    ]

    bundle = {
        "gameweek": gameweek,
        "model_version": model_version,
        "input_hash": input_hash.hex(),
        "inputs_as_of": inputs_as_of.isoformat(),
        "generated_at": datetime.now(UTC).isoformat(),
        "players": players_list,
    }

    pub_stmt = pg_insert(PublishedProjection).values(
        {
            "gameweek": gameweek,
            "run_id": run_id,
            "published_at": datetime.now(UTC),
            "bundle_json": bundle,
        }
    )
    pub_stmt = pub_stmt.on_conflict_do_update(
        index_elements=["gameweek"],
        set_={
            "run_id": pub_stmt.excluded.run_id,
            "published_at": pub_stmt.excluded.published_at,
            "bundle_json": pub_stmt.excluded.bundle_json,
        },
    )
    db.execute(pub_stmt)


def run_projection_job(db: Session, gameweek: int | None = None) -> dict[str, Any]:
    """
    Entry point for the /internal/jobs/project trigger.
    Tracks execution in ingestion_runs table.
    """
    started_at = datetime.now(UTC)
    run_log = IngestionRun(
        job_name="project",
        started_at=started_at,
        status="RUNNING",
    )
    db.add(run_log)
    db.commit()

    try:
        if gameweek is None:
            # Determine next or current gameweek
            gw = (
                db.query(Gameweek)
                .filter(Gameweek.finished.is_(False))
                .order_by(Gameweek.id.asc())
                .first()
            )
            if not gw:
                gw = db.query(Gameweek).order_by(Gameweek.id.desc()).first()
            if not gw or gw.id is None:
                run_log.status = "FAILED"  # type: ignore[assignment]
                run_log.finished_at = datetime.now(UTC)  # type: ignore[assignment]
                run_log.error_summary = "No gameweek found"  # type: ignore[assignment]
                db.commit()
                return {"status": "FAILED", "error": "No gameweek found"}
            target_gw = int(gw.id)
        else:
            target_gw = gameweek

        res = run_projections_for_gameweek(db, target_gameweek=target_gw)
        run_log.status = "OK"  # type: ignore[assignment]
        run_log.finished_at = datetime.now(UTC)  # type: ignore[assignment]
        run_log.rows_written = res.get("projections_count", 0)  # type: ignore[assignment]
        db.commit()
        return res
    except Exception as exc:
        db.rollback()
        run_log.status = "FAILED"  # type: ignore[assignment]
        run_log.finished_at = datetime.now(UTC)  # type: ignore[assignment]
        run_log.error_summary = str(exc)  # type: ignore[assignment]
        db.commit()
        raise
