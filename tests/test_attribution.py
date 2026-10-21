"""
Tests for Attribution Template Engine (Backend Design §6.6, Spec §3 & §4).
Verifies:
1. Full projections generate all attribution lines deterministically.
2. Removing each field in turn omits only that line, never inventing a missing number.
"""

import pytest

from fpl_lens.engine.attribution import AttributionEngine


@pytest.fixture
def full_projection_data() -> dict:
    return {
        "availability": 0.85,
        "p_start": 0.90,
        "expected_minutes": 82.0,
        "exp_goals": 0.65,
        "exp_assists": 0.35,
        "exp_clean_sheet": 0.40,
        "exp_goals_conceded": -0.50,
        "exp_dc": 0.25,
        "exp_bonus": 0.70,
        "exp_card_penalty": -0.10,
    }


def test_full_projection_produces_all_attributions(full_projection_data: dict):
    lines = AttributionEngine.generate_attributions(full_projection_data)
    assert len(lines) == 10
    assert lines[0] == "Availability (α): 85% (Share of expected availability)"
    assert lines[1] == "Start probability: 90%"
    assert lines[2] == "Expected minutes: 82"
    assert lines[3] == "Expected goals (xG): 0.65"
    assert lines[4] == "Expected assists (xA): 0.35"
    assert lines[5] == "Clean sheet probability: 40%"
    assert lines[6] == "Goals-conceded penalty: -0.50"
    assert lines[7] == "Defensive contributions: 25% chance of threshold"
    assert lines[8] == "Expected bonus: 0.70"
    assert lines[9] == "Card penalty: -0.10"


@pytest.mark.parametrize(
    "removed_field,expected_missing_keyword",
    [
        ("availability", "Availability"),
        ("p_start", "Start probability"),
        ("expected_minutes", "Expected minutes"),
        ("exp_goals", "Expected goals (xG)"),
        ("exp_assists", "Expected assists (xA)"),
        ("exp_clean_sheet", "Clean sheet"),
        ("exp_goals_conceded", "Goals-conceded"),
        ("exp_dc", "Defensive contributions"),
        ("exp_bonus", "Expected bonus"),
        ("exp_card_penalty", "Card penalty"),
    ],
)
def test_omit_line_when_field_is_missing(
    full_projection_data: dict, removed_field: str, expected_missing_keyword: str
):
    # Remove field
    modified_data = dict(full_projection_data)
    del modified_data[removed_field]

    lines = AttributionEngine.generate_attributions(modified_data)
    assert len(lines) == 9

    # Verify missing line is not present
    for line in lines:
        assert expected_missing_keyword not in line


def test_nested_components_structure(full_projection_data: dict):
    nested_data = {
        "availability": 1.0,
        "p_start": 0.95,
        "expected_minutes": 90,
        "components": {
            "exp_goals": 0.80,
            "exp_assists": 0.20,
            "exp_clean_sheet": 0.50,
            "exp_goals_conceded": -0.30,
            "exp_dc": 0.15,
            "exp_bonus": 1.20,
            "exp_card_penalty": -0.05,
        },
    }
    lines = AttributionEngine.generate_attributions(nested_data)
    assert len(lines) == 10
    assert "Expected goals (xG): 0.80" in lines
    assert "Clean sheet probability: 50%" in lines


def test_empty_projection_produces_empty_list():
    lines = AttributionEngine.generate_attributions({})
    assert lines == []
