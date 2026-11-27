"""
Data Quality Gates and Player Identity checks per Engine Design §4.3 & §4.7.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta
from typing import Any

from fpl_lens.rules.rules_table import get_rule

DEFAULT_STALE_MINUTES = 30
MAX_PRICE_JUMP_TENTHS = 10  # £1.0m
MAX_STATUS_CHANGES = 30


@dataclass
class QualityGateReport:
    accepted: bool
    rejected_reason: str | None = None
    quarantined_player_ids: list[int] = field(default_factory=list)
    quarantined_fixture_ids: list[int] = field(default_factory=list)
    duplicate_name_team_pairs: list[tuple[str, int]] = field(default_factory=list)
    alerts: list[str] = field(default_factory=list)


def is_snapshot_stale(
    fetched_at: datetime | None,
    now: datetime | None = None,
    max_age_minutes: int = DEFAULT_STALE_MINUTES,
) -> bool:
    """Returns True if snapshot is missing or older than max_age_minutes (§4.7, I16)."""
    if fetched_at is None:
        return True
    ref_now = now or datetime.now(UTC)
    ts = fetched_at if fetched_at.tzinfo is not None else fetched_at.replace(tzinfo=UTC)
    return (ref_now - ts) > timedelta(minutes=max_age_minutes)


def validate_bootstrap_snapshot(
    data: dict[str, Any],
    previous_data: dict[str, Any] | None = None,
) -> QualityGateReport:
    """
    Validates bootstrap-static payload against §4.3 & §4.7 gates:
      - Unique element ids (reject snapshot if violated)
      - Unique non-null element codes (reject snapshot if violated)
      - Duplicate (web_name, team) pairs flagged for review (never silently merged)
      - Missing team/position/price quarantines the player
      - Plausibility counts (20 teams, 38 gameweeks) -> alert
      - Sudden large jumps vs previous_data (>£1.0m price jump or >30 status changes) -> alert
    """
    report = QualityGateReport(accepted=True)

    teams = data.get("teams")
    events = data.get("events")
    elements = data.get("elements")
    if not isinstance(teams, list) or not isinstance(events, list) or not isinstance(elements, list):
        return QualityGateReport(
            accepted=False,
            rejected_reason="Schema invalid: teams, events, and elements must be lists",
        )

    team_ids = {t.get("id") for t in teams if isinstance(t, dict) and t.get("id") is not None}
    expected_gws = int(get_rule("total_gameweeks").value)
    if len(team_ids) != 20:
        report.alerts.append(f"Unexpected team count: {len(team_ids)} (expected 20)")
    if len(events) != expected_gws:
        report.alerts.append(f"Unexpected gameweek count: {len(events)} (expected {expected_gws})")

    seen_ids: set[int] = set()
    seen_codes: set[int] = set()
    seen_name_team: dict[tuple[str, int], int] = {}

    for raw in elements:
        if not isinstance(raw, dict):
            continue
        eid = raw.get("id")
        if not isinstance(eid, int):
            return QualityGateReport(
                accepted=False,
                rejected_reason="Element missing integer id",
            )
        if eid in seen_ids:
            return QualityGateReport(
                accepted=False,
                rejected_reason=f"Duplicate element id detected: {eid}",
            )
        seen_ids.add(eid)

        code = raw.get("code")
        if isinstance(code, int):
            if code in seen_codes:
                return QualityGateReport(
                    accepted=False,
                    rejected_reason=f"Duplicate player code detected: {code}",
                )
            seen_codes.add(code)

        team_id = raw.get("team")
        elem_type = raw.get("element_type")
        now_cost = raw.get("now_cost")
        if (
            not isinstance(team_id, int)
            or team_id not in team_ids
            or elem_type not in (1, 2, 3, 4)
            or not isinstance(now_cost, int)
            or now_cost <= 0
        ):
            report.quarantined_player_ids.append(eid)
            continue

        web_name = str(raw.get("web_name") or "").strip()
        if web_name:
            pair = (web_name, team_id)
            if pair in seen_name_team:
                report.duplicate_name_team_pairs.append(pair)
                report.alerts.append(
                    f"Duplicate (web_name, team) pair '{web_name}' in team {team_id}: "
                    f"ids {seen_name_team[pair]} and {eid}"
                )
            else:
                seen_name_team[pair] = eid

    if previous_data and isinstance(previous_data.get("elements"), list):
        prev_by_id = {
            e["id"]: e
            for e in previous_data["elements"]
            if isinstance(e, dict) and isinstance(e.get("id"), int)
        }
        status_changes = 0
        for raw in elements:
            if not isinstance(raw, dict):
                continue
            eid = raw.get("id")
            if eid not in prev_by_id:
                continue
            prev = prev_by_id[eid]
            cur_cost = raw.get("now_cost")
            prev_cost = prev.get("now_cost")
            if isinstance(cur_cost, int) and isinstance(prev_cost, int):
                if abs(cur_cost - prev_cost) > MAX_PRICE_JUMP_TENTHS:
                    report.alerts.append(
                        f"Sudden price jump for element {eid}: {prev_cost} -> {cur_cost}"
                    )
            if raw.get("status") != prev.get("status"):
                status_changes += 1
        if status_changes > MAX_STATUS_CHANGES:
            report.alerts.append(
                f"Sudden status wave: {status_changes} status changes (> {MAX_STATUS_CHANGES})"
            )

    return report


def validate_fixtures_snapshot(
    fixtures: list[dict[str, Any]],
    valid_team_ids: set[int],
) -> QualityGateReport:
    """Validates fixtures list: every fixture's teams must exist (§4.7)."""
    report = QualityGateReport(accepted=True)
    for raw in fixtures:
        if not isinstance(raw, dict):
            continue
        fid = raw.get("id")
        th = raw.get("team_h")
        ta = raw.get("team_a")
        if (
            not isinstance(fid, int)
            or not isinstance(th, int)
            or not isinstance(ta, int)
            or th not in valid_team_ids
            or ta not in valid_team_ids
            or th == ta
        ):
            if isinstance(fid, int):
                report.quarantined_fixture_ids.append(fid)
            report.alerts.append(f"Quarantined fixture {fid}: invalid teams ({th}, {ta})")
    return report
