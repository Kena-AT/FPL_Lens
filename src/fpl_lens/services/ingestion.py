from datetime import UTC, datetime
from typing import Any

import httpx
from pydantic import ValidationError
from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from fpl_lens.api.schemas.fpl import (
    FPLElementHistorySchema,
    FPLElementSchema,
    FPLEventSchema,
    FPLFixtureSchema,
    FPLTeamSchema,
)
from fpl_lens.db.models import (
    CacheEntry,
    Fixture,
    Gameweek,
    IngestionRun,
    Player,
    PlayerFixtureStat,
    Team,
)
from fpl_lens.logging import logger
from fpl_lens.services.cache import set_cached_value
from fpl_lens.services.cleanup import cleanup_expired_accounts
from fpl_lens.services.fpl_client import UpstreamUnavailableError, fpl_client

POSITION_MAP = {
    1: "GK",
    2: "DEF",
    3: "MID",
    4: "FWD",
}


def _create_ingestion_run(db: Session, job_name: str) -> IngestionRun:
    run = IngestionRun(
        job_name=job_name,
        started_at=datetime.now(UTC),
        status="RUNNING",
        rows_written=0,
    )
    db.add(run)
    db.commit()
    db.refresh(run)
    return run


def _finish_ingestion_run(
    db: Session,
    run: IngestionRun,
    status: str,
    rows_written: int,
    error_summary: str | None = None,
) -> None:
    run.status = status
    run.rows_written = rows_written
    run.error_summary = error_summary
    run.finished_at = datetime.now(UTC)
    db.commit()


async def run_bootstrap_job(db: Session, bootstrap_data: dict[str, Any] | None = None) -> dict[str, Any]:
    """
    Ingests FPL bootstrap-static: teams, gameweeks (events), and players (elements).
    Validates each record against Pydantic schemas.
    Failed records are logged and skipped, never defaulted to zero.
    Marks status PARTIAL if any records fail.
    """
    run = _create_ingestion_run(db, "bootstrap")
    failed_records = 0
    total_written = 0
    errors: list[str] = []

    try:
        data = bootstrap_data or await fpl_client.get_bootstrap_static(enforce_throttle=False)

        # 1. Teams
        team_values = []
        for raw_team in data.get("teams", []):
            try:
                t = FPLTeamSchema.model_validate(raw_team)
                team_values.append(
                    {
                        "fpl_id": t.id,
                        "name": t.name,
                        "short_name": t.short_name,
                        "strength_attack_home": t.strength_attack_home,
                        "strength_attack_away": t.strength_attack_away,
                        "strength_defence_home": t.strength_defence_home,
                        "strength_defence_away": t.strength_defence_away,
                        "updated_at": datetime.now(UTC),
                    }
                )
            except (ValidationError, ValueError) as exc:
                failed_records += 1
                msg = f"Team {raw_team.get('id')} validation failed: {exc}"
                logger.error(msg)
                errors.append(msg)

        if team_values:
            stmt = insert(Team).values(team_values)
            stmt = stmt.on_conflict_do_update(
                index_elements=["fpl_id"],
                set_={
                    "name": stmt.excluded.name,
                    "short_name": stmt.excluded.short_name,
                    "strength_attack_home": stmt.excluded.strength_attack_home,
                    "strength_attack_away": stmt.excluded.strength_attack_away,
                    "strength_defence_home": stmt.excluded.strength_defence_home,
                    "strength_defence_away": stmt.excluded.strength_defence_away,
                    "updated_at": stmt.excluded.updated_at,
                },
            )
            db.execute(stmt)
            total_written += len(team_values)

        db.flush()

        # 2. Gameweeks (Events)
        event_values = []
        for raw_event in data.get("events", []):
            try:
                e = FPLEventSchema.model_validate(raw_event)
                event_values.append(
                    {
                        "id": e.id,
                        "name": e.name,
                        "deadline_time": e.deadline_time,
                        "finished": e.finished,
                        "is_current": e.is_current,
                        "is_next": e.is_next,
                    }
                )
            except (ValidationError, ValueError) as exc:
                failed_records += 1
                msg = f"Gameweek {raw_event.get('id')} validation failed: {exc}"
                logger.error(msg)
                errors.append(msg)

        if event_values:
            stmt = insert(Gameweek).values(event_values)
            stmt = stmt.on_conflict_do_update(
                index_elements=["id"],
                set_={
                    "name": stmt.excluded.name,
                    "deadline_time": stmt.excluded.deadline_time,
                    "finished": stmt.excluded.finished,
                    "is_current": stmt.excluded.is_current,
                    "is_next": stmt.excluded.is_next,
                },
            )
            db.execute(stmt)
            total_written += len(event_values)

        db.flush()

        # 3. Players (Elements)
        element_values = []
        for raw_element in data.get("elements", []):
            try:
                el = FPLElementSchema.model_validate(raw_element)
                pos = POSITION_MAP.get(el.element_type)
                if not pos:
                    raise ValueError(f"Unknown element_type: {el.element_type}")

                element_values.append(
                    {
                        "fpl_id": el.id,
                        "first_name": el.first_name,
                        "second_name": el.second_name,
                        "web_name": el.web_name,
                        "position": pos,
                        "team_fpl_id": el.team,
                        "now_cost": el.now_cost,
                        "status": el.status,
                        "chance_of_playing_next_round": el.chance_of_playing_next_round,
                        "news": el.news,
                        "news_added_at": el.news_added,
                        "expected_goals_season": el.expected_goals,
                        "expected_assists_season": el.expected_assists,
                        "updated_at": datetime.now(UTC),
                    }
                )
            except (ValidationError, ValueError) as exc:
                failed_records += 1
                msg = f"Player {raw_element.get('id')} validation failed: {exc}"
                logger.error(msg)
                errors.append(msg)

        if element_values:
            stmt = insert(Player).values(element_values)
            stmt = stmt.on_conflict_do_update(
                index_elements=["fpl_id"],
                set_={
                    "first_name": stmt.excluded.first_name,
                    "second_name": stmt.excluded.second_name,
                    "web_name": stmt.excluded.web_name,
                    "position": stmt.excluded.position,
                    "team_fpl_id": stmt.excluded.team_fpl_id,
                    "now_cost": stmt.excluded.now_cost,
                    "status": stmt.excluded.status,
                    "chance_of_playing_next_round": stmt.excluded.chance_of_playing_next_round,
                    "news": stmt.excluded.news,
                    "news_added_at": stmt.excluded.news_added_at,
                    "expected_goals_season": stmt.excluded.expected_goals_season,
                    "expected_assists_season": stmt.excluded.expected_assists_season,
                    "updated_at": stmt.excluded.updated_at,
                },
            )
            db.execute(stmt)
            total_written += len(element_values)

        # Cache raw summary in cache_entries per Backend Design §9
        set_cached_value(
            db,
            "fpl:bootstrap",
            {"events": len(data.get("events", [])), "teams": len(data.get("teams", [])), "elements": len(data.get("elements", []))},
            ttl_seconds=1800,
        )

        db.commit()

        status_result = "PARTIAL" if failed_records > 0 else "OK"
        summary = f"{failed_records} records failed validation" if failed_records > 0 else None
        _finish_ingestion_run(db, run, status_result, total_written, summary)

        return {
            "run_id": run.id,
            "job": "bootstrap",
            "status": status_result,
            "rows_written": total_written,
            "failed_records": failed_records,
        }

    except Exception as exc:
        db.rollback()
        logger.exception("Bootstrap job failed fatally: %s", exc)
        _finish_ingestion_run(db, run, "FAILED", total_written, str(exc))
        raise


async def run_fixtures_job(db: Session, fixtures_data: list[dict[str, Any]] | None = None) -> dict[str, Any]:
    """
    Ingests FPL fixtures.
    Validates each fixture against FPLFixtureSchema.
    """
    run = _create_ingestion_run(db, "fixtures")
    failed_records = 0
    total_written = 0

    try:
        data = fixtures_data or await fpl_client.get_fixtures()
        fixture_values = []

        for raw_fix in data:
            try:
                f = FPLFixtureSchema.model_validate(raw_fix)
                fixture_values.append(
                    {
                        "fpl_id": f.id,
                        "gameweek": f.event,
                        "kickoff_time": f.kickoff_time,
                        "home_team_fpl_id": f.team_h,
                        "away_team_fpl_id": f.team_a,
                        "finished": f.finished,
                        "home_score": f.team_h_score,
                        "away_score": f.team_a_score,
                        "updated_at": datetime.now(UTC),
                    }
                )
            except (ValidationError, ValueError) as exc:
                failed_records += 1
                logger.error("Fixture %s validation failed: %s", raw_fix.get("id"), exc)

        if fixture_values:
            stmt = insert(Fixture).values(fixture_values)
            stmt = stmt.on_conflict_do_update(
                index_elements=["fpl_id"],
                set_={
                    "gameweek": stmt.excluded.gameweek,
                    "kickoff_time": stmt.excluded.kickoff_time,
                    "home_team_fpl_id": stmt.excluded.home_team_fpl_id,
                    "away_team_fpl_id": stmt.excluded.away_team_fpl_id,
                    "finished": stmt.excluded.finished,
                    "home_score": stmt.excluded.home_score,
                    "away_score": stmt.excluded.away_score,
                    "updated_at": stmt.excluded.updated_at,
                },
            )
            db.execute(stmt)
            total_written += len(fixture_values)

        db.commit()

        status_result = "PARTIAL" if failed_records > 0 else "OK"
        summary = f"{failed_records} fixtures failed validation" if failed_records > 0 else None
        _finish_ingestion_run(db, run, status_result, total_written, summary)

        return {
            "run_id": run.id,
            "job": "fixtures",
            "status": status_result,
            "rows_written": total_written,
            "failed_records": failed_records,
        }

    except Exception as exc:
        db.rollback()
        logger.exception("Fixtures job failed fatally: %s", exc)
        _finish_ingestion_run(db, run, "FAILED", total_written, str(exc))
        raise


async def run_history_job(
    db: Session,
    player_ids: list[int] | None = None,
    mock_history_map: dict[int, dict[str, Any]] | None = None,
    max_players: int | None = None,
) -> dict[str, Any]:
    """
    Ingests player match history from element-summary.
    Throttled per player request. Writes player_fixture_stats.
    """
    run = _create_ingestion_run(db, "history")
    failed_records = 0
    total_written = 0

    try:
        # Determine player target list
        if player_ids is None:
            stmt = select(Player.fpl_id).where(Player.status != "u").order_by(Player.fpl_id)
            if max_players:
                stmt = stmt.limit(max_players)
            target_players = list(db.execute(stmt).scalars().all())
        else:
            target_players = player_ids

        now = datetime.now(UTC)

        for pid in target_players:
            try:
                if mock_history_map and pid in mock_history_map:
                    summary_data = mock_history_map[pid]
                else:
                    summary_data = await fpl_client.get_element_summary(pid)

                if not summary_data:
                    continue

                for raw_match in summary_data.get("history", []):
                    try:
                        h = FPLElementHistorySchema.model_validate(raw_match)
                        stmt = insert(PlayerFixtureStat).values(
                            player_fpl_id=h.element,
                            fixture_fpl_id=h.fixture,
                            gameweek=h.round,
                            was_starter=bool(h.starts == 1),
                            minutes=h.minutes,
                            total_points=h.total_points,
                            goals_scored=h.goals_scored,
                            assists=h.assists,
                            clean_sheets=h.clean_sheets,
                            goals_conceded=h.goals_conceded,
                            defensive_contributions=h.defensive_contribution,
                            bps=h.bps,
                            bonus=h.bonus,
                            yellow_cards=h.yellow_cards,
                            red_cards=h.red_cards,
                            source_fetched_at=now,
                        )
                        stmt = stmt.on_conflict_do_update(
                            index_elements=["player_fpl_id", "fixture_fpl_id"],
                            set_={
                                "gameweek": stmt.excluded.gameweek,
                                "was_starter": stmt.excluded.was_starter,
                                "minutes": stmt.excluded.minutes,
                                "total_points": stmt.excluded.total_points,
                                "goals_scored": stmt.excluded.goals_scored,
                                "assists": stmt.excluded.assists,
                                "clean_sheets": stmt.excluded.clean_sheets,
                                "goals_conceded": stmt.excluded.goals_conceded,
                                "defensive_contributions": stmt.excluded.defensive_contributions,
                                "bps": stmt.excluded.bps,
                                "bonus": stmt.excluded.bonus,
                                "yellow_cards": stmt.excluded.yellow_cards,
                                "red_cards": stmt.excluded.red_cards,
                                "source_fetched_at": stmt.excluded.source_fetched_at,
                            },
                        )
                        db.execute(stmt)
                        total_written += 1
                    except (ValidationError, ValueError) as exc:
                        failed_records += 1
                        logger.error("Player %d match record failed validation: %s", pid, exc)

                db.flush()

            except (httpx.HTTPError, UpstreamUnavailableError, SQLAlchemyError, ValueError, ValidationError) as exc:
                failed_records += 1
                logger.error("Failed fetching or processing summary for player %d: %s", pid, exc)

        db.commit()

        status_result = "PARTIAL" if failed_records > 0 else "OK"
        summary = f"{failed_records} history records failed validation" if failed_records > 0 else None
        _finish_ingestion_run(db, run, status_result, total_written, summary)

        return {
            "run_id": run.id,
            "job": "history",
            "status": status_result,
            "rows_written": total_written,
            "failed_records": failed_records,
        }

    except Exception as exc:
        db.rollback()
        logger.exception("History job failed fatally: %s", exc)
        _finish_ingestion_run(db, run, "FAILED", total_written, str(exc))
        raise


async def run_cleanup_job(db: Session) -> dict[str, Any]:
    """
    Cleans up expired accounts, tokens, email codes, and expired cache entries.
    """
    run = _create_ingestion_run(db, "cleanup")
    try:
        # Accounts and tokens cleanup
        acct_stats = cleanup_expired_accounts(db)

        # Cache cleanup
        now = datetime.now(UTC)
        cache_del_stmt = delete(CacheEntry).where(CacheEntry.expires_at <= now)
        res = db.execute(cache_del_stmt)
        cache_deleted = res.rowcount or 0
        db.commit()

        rows_written = acct_stats["unverified_deleted"] + acct_stats["pending_deletion_deleted"] + cache_deleted
        _finish_ingestion_run(db, run, "OK", rows_written)

        return {
            "run_id": run.id,
            "job": "cleanup",
            "status": "OK",
            "rows_written": rows_written,
            "stats": {**acct_stats, "cache_deleted": cache_deleted},
        }
    except Exception as exc:
        db.rollback()
        _finish_ingestion_run(db, run, "FAILED", 0, str(exc))
        raise
