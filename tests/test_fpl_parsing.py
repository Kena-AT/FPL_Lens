import json
from decimal import Decimal
from pathlib import Path

import pytest
from pydantic import ValidationError

from fpl_lens.api.schemas.fpl import (
    FPLElementHistorySchema,
    FPLElementSchema,
    FPLEventSchema,
    FPLFixtureSchema,
    FPLHistoryResponseSchema,
    FPLPicksResponseSchema,
    FPLTeamSchema,
    FPLTransferItemSchema,
    parse_strict_numeric,
)

FIXTURES_DIR = Path(__file__).parent / "fixtures"


def test_fixture_files_exist_and_parse():
    """Verifies that all 7 recorded FPL response fixtures exist and parse cleanly into expected objects."""
    # 1. bootstrap_static
    with open(FIXTURES_DIR / "bootstrap_static.json", encoding="utf-8") as f:
        bootstrap = json.load(f)
    teams = [FPLTeamSchema.model_validate(t) for t in bootstrap["teams"]]
    events = [FPLEventSchema.model_validate(e) for e in bootstrap["events"]]
    elements = [FPLElementSchema.model_validate(el) for el in bootstrap["elements"]]
    assert len(teams) == 20
    assert len(events) == 38
    assert len(elements) > 500

    # 2. fixtures
    with open(FIXTURES_DIR / "fixtures.json", encoding="utf-8") as f:
        fixtures_data = json.load(f)
    fixtures = [FPLFixtureSchema.model_validate(fix) for fix in fixtures_data]
    assert len(fixtures) == 380

    # 3. element_summary
    with open(FIXTURES_DIR / "element_summary.json", encoding="utf-8") as f:
        summary_data = json.load(f)
    history = [FPLElementHistorySchema.model_validate(h) for h in summary_data.get("history", [])]
    assert len(history) > 0

    # 4. entry
    with open(FIXTURES_DIR / "entry.json", encoding="utf-8") as f:
        entry_data = json.load(f)
    assert entry_data["id"] == 1
    assert "name" in entry_data

    # 5. picks
    with open(FIXTURES_DIR / "picks.json", encoding="utf-8") as f:
        picks_data = json.load(f)
    picks_parsed = FPLPicksResponseSchema.model_validate(picks_data)
    assert len(picks_parsed.picks) == 15

    # 6. history
    with open(FIXTURES_DIR / "history.json", encoding="utf-8") as f:
        history_data = json.load(f)
    history_parsed = FPLHistoryResponseSchema.model_validate(history_data)
    assert isinstance(history_parsed.current, list)

    # 7. transfers
    with open(FIXTURES_DIR / "transfers.json", encoding="utf-8") as f:
        transfers_data = json.load(f)
    transfers = [FPLTransferItemSchema.model_validate(t) for t in transfers_data]
    assert len(transfers) > 0


def test_strict_numeric_string_parsing_failure():
    """
    Spec & Implementation Plan requirement:
    A numeric string such as 'abc' fails its record and is logged,
    and the stored value is not zero.
    """
    # 1. Direct unit test of strict numeric parser
    with pytest.raises(ValueError, match="failed to parse from string 'abc'"):
        parse_strict_numeric("abc", "expected_goals")

    with pytest.raises(ValueError, match="is empty"):
        parse_strict_numeric("", "expected_goals")

    with pytest.raises(ValueError, match="is None"):
        parse_strict_numeric(None, "expected_goals")

    # 2. Schema validation level failure
    raw_element = {
        "id": 9999,
        "first_name": "Test",
        "second_name": "Player",
        "web_name": "Player",
        "element_type": 3,
        "team": 1,
        "now_cost": 50,
        "status": "a",
        "expected_goals": "abc",  # unparseable string
        "expected_assists": "0.15",
    }
    with pytest.raises(ValidationError) as exc_info:
        FPLElementSchema.model_validate(raw_element)

    assert "expected_goals" in str(exc_info.value)

    # Verify that the value is NEVER defaulted to zero
    assert "0" not in str(exc_info.value)


def test_expected_goals_matches_raw_response():
    """
    Spec & Implementation Plan requirement:
    The expected_goals value for a known player matches the value in the raw FPL response, within rounding.
    """
    with open(FIXTURES_DIR / "bootstrap_static.json", encoding="utf-8") as f:
        bootstrap = json.load(f)

    # Check first element in bootstrap fixture
    raw_player = bootstrap["elements"][0]
    parsed_player = FPLElementSchema.model_validate(raw_player)

    raw_xg_str = raw_player.get("expected_goals", "0.00")
    expected_xg = Decimal(raw_xg_str)

    assert parsed_player.expected_goals == expected_xg
    assert float(parsed_player.expected_goals) == pytest.approx(float(raw_xg_str), abs=1e-3)
