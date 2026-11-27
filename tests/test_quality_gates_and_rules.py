from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy.orm import Session

from fpl_lens.rules.rules_table import RULES_TABLE, RULES_TABLE_VERSION, get_rule, get_verify_rules
from fpl_lens.services.ingestion import run_bootstrap_job
from fpl_lens.services.quality_gates import (
    is_snapshot_stale,
    validate_bootstrap_snapshot,
    validate_fixtures_snapshot,
)


def _make_valid_bootstrap() -> dict:
    return {
        "teams": [
            {
                "id": i,
                "name": f"Team {i}",
                "short_name": f"T{i:02d}",
                "strength_attack_home": 1100,
                "strength_attack_away": 1050,
                "strength_defence_home": 1100,
                "strength_defence_away": 1050,
            }
            for i in range(1, 21)
        ],
        "events": [
            {
                "id": g,
                "name": f"Gameweek {g}",
                "deadline_time": "2026-12-01T11:00:00Z",
                "finished": False,
                "is_current": g == 1,
                "is_next": g == 2,
            }
            for g in range(1, 39)
        ],
        "elements": [
            {
                "id": 355,
                "code": 223094,
                "first_name": "Erling",
                "second_name": "Haaland",
                "web_name": "Haaland",
                "element_type": 4,
                "team": 13,
                "now_cost": 152,
                "status": "a",
                "chance_of_playing_this_round": 100,
                "chance_of_playing_next_round": 100,
                "expected_goals": "10.50",
                "expected_assists": "1.20",
                "form": "8.5",
                "points_per_game": "7.9",
                "selected_by_percent": "62.1",
            },
            {
                "id": 328,
                "code": 118748,
                "first_name": "Mohamed",
                "second_name": "Salah",
                "web_name": "Salah",
                "element_type": 3,
                "team": 12,
                "now_cost": 130,
                "status": "a",
                "chance_of_playing_this_round": 100,
                "chance_of_playing_next_round": 100,
                "expected_goals": "8.20",
                "expected_assists": "4.50",
                "form": "9.1",
                "points_per_game": "8.4",
                "selected_by_percent": "55.0",
            },
        ],
    }


def test_rules_table_has_verified_and_verify_rows():
    assert RULES_TABLE_VERSION == "2026-27.1"
    assert len(RULES_TABLE) > 20
    assert get_rule("squad_size").value == 15
    assert get_rule("squad_size").state == "VERIFIED-OFFICIAL"
    verify_rows = get_verify_rules()
    assert any(r.key == "gw19_deadline_from_api" for r in verify_rows)
    with pytest.raises(KeyError):
        get_rule("nonexistent_rule")


def test_quality_gate_rejects_duplicate_element_id():
    data = _make_valid_bootstrap()
    data["elements"].append(dict(data["elements"][0], code=999999))
    report = validate_bootstrap_snapshot(data)
    assert report.accepted is False
    assert "Duplicate element id" in (report.rejected_reason or "")


def test_quality_gate_rejects_duplicate_code():
    data = _make_valid_bootstrap()
    data["elements"].append(dict(data["elements"][0], id=999))  # same code 223094
    report = validate_bootstrap_snapshot(data)
    assert report.accepted is False
    assert "Duplicate player code" in (report.rejected_reason or "")


def test_quality_gate_flags_duplicate_name_team_pair_f1_to_f4():
    """Reproduces F1-F4 scenario where two distinct element records share (web_name, team)."""
    data = _make_valid_bootstrap()
    dup_haaland = dict(data["elements"][0], id=999, code=888888, now_cost=156)
    data["elements"].append(dup_haaland)
    report = validate_bootstrap_snapshot(data)
    assert report.accepted is True
    assert ("Haaland", 13) in report.duplicate_name_team_pairs
    assert any("Haaland" in a for a in report.alerts)


def test_quality_gate_quarantines_invalid_player_and_fixture():
    data = _make_valid_bootstrap()
    data["elements"].append({"id": 777, "code": 777777, "team": 99, "element_type": 3, "now_cost": 50})
    report = validate_bootstrap_snapshot(data)
    assert report.accepted is True
    assert 777 in report.quarantined_player_ids

    fx_report = validate_fixtures_snapshot(
        [{"id": 1, "team_h": 1, "team_a": 2}, {"id": 2, "team_h": 1, "team_a": 99}],
        valid_team_ids=set(range(1, 21)),
    )
    assert fx_report.quarantined_fixture_ids == [2]


def test_quality_gate_alerts_on_sudden_price_jump_and_staleness():
    prev = _make_valid_bootstrap()
    curr = _make_valid_bootstrap()
    curr["elements"][0]["now_cost"] = 170  # +18 tenths (> £1.0m)
    report = validate_bootstrap_snapshot(curr, previous_data=prev)
    assert any("Sudden price jump" in a for a in report.alerts)

    now = datetime(2026, 11, 27, 12, 0, tzinfo=UTC)
    assert is_snapshot_stale(now - timedelta(minutes=31), now) is True
    assert is_snapshot_stale(now - timedelta(minutes=15), now) is False
    assert is_snapshot_stale(None, now) is True


async def test_bootstrap_job_rejects_duplicate_id_snapshot(db_session: Session):
    bad_data = _make_valid_bootstrap()
    bad_data["elements"].append(dict(bad_data["elements"][0]))
    with pytest.raises(ValueError, match="Duplicate element id"):
        await run_bootstrap_job(db_session, bootstrap_data=bad_data)
