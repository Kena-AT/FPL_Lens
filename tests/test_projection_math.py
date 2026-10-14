import math

import pytest

from fpl_lens.engine.availability import calculate_availability
from fpl_lens.engine.components import (
    calculate_clean_sheet_points,
    calculate_goals_and_assists,
    calculate_goals_conceded_penalty,
    compute_projection_components,
)
from fpl_lens.engine.intensities import calculate_team_intensities, compute_league_averages
from fpl_lens.engine.playing_time import calculate_playing_time
from fpl_lens.engine.types import PlayerMatchHistory, TeamStrength


def test_availability_calculation():
    """Spec §3.1: Alpha(p) computation across all player statuses."""
    # Available -> 1.0
    assert calculate_availability("a", None) == 1.0
    assert calculate_availability("A", 100) == 1.0

    # Doubtful with specified chance
    assert calculate_availability("d", 75) == 0.75
    assert calculate_availability("d", 50) == 0.50
    assert calculate_availability("d", 25) == 0.25

    # Doubtful with missing chance defaults to 0.5 [PLACEHOLDER]
    assert calculate_availability("d", None) == 0.5

    # Injured, suspended, unavailable -> 0.0
    assert calculate_availability("i", 75) == 0.0
    assert calculate_availability("s", None) == 0.0
    assert calculate_availability("u", 100) == 0.0
    assert calculate_availability("", None) == 0.0


def test_playing_time_scenarios_and_rates():
    """Spec §3.2: 5-scenario partition and expected minutes."""
    # Player started 5 out of 5 matches with 90 min each
    history = [
        PlayerMatchHistory(gameweek=i, was_starter=True, minutes=90)
        for i in range(1, 6)
    ]
    pt = calculate_playing_time(
        availability=1.0,
        history=history,
        position="MID",
        shrinkage_weight=0.0,  # pure empirical to check formula
    )

    assert pt.availability == 1.0
    assert pt.p_start == 1.0
    assert pt.p_sub == 0.0
    assert pt.p_se == 1.0
    assert pt.p_sd == 0.0
    assert pt.p_sa == 0.0
    assert pt.expected_minutes == 90.0


def test_team_intensities():
    """Spec §3.3: Attack and defence intensities."""
    teams = [
        TeamStrength(1, "Arsenal", "ARS", 1250, 1200, 1300, 1250),
        TeamStrength(2, "Chelsea", "CHE", 1150, 1100, 1150, 1100),
    ]
    averages = compute_league_averages(teams, total_goals=1000, matches_played=380)
    assert pytest.approx(averages["mu"], abs=1e-3) == 1000 / (2 * 380)

    # Home team Arsenal vs Away team Chelsea
    lam_scored, lam_conceded = calculate_team_intensities(
        team=teams[0],
        opponent=teams[1],
        is_home=True,
        league_averages=averages,
    )
    assert lam_scored > 0
    assert lam_conceded > 0
    # Arsenal has stronger attack than Chelsea defense -> lam_scored > mu
    assert lam_scored > averages["mu"]


def test_goals_and_assists_worked_example():
    """Spec §4.2: Matches the worked example from Technical Spec §4.2."""
    # Worked example in Spec §4.2:
    # xG90 = 0.65, E[Min] = 70, lambda_scored = 1.8, mu = 1.35, pos = MID (W_goal = 5)
    # Expected goals points: 0.65 * (70 / 90) * (1.8 / 1.35) * 5 = 3.37
    exp_goals, exp_assists = calculate_goals_and_assists(
        xg_90=0.65,
        xa_90=0.20,
        expected_minutes=70.0,
        lambda_scored=1.8,
        mu=1.35,
        position="MID",
    )
    expected_goals_pts = 0.65 * (70.0 / 90.0) * (1.8 / 1.35) * 5.0
    assert pytest.approx(exp_goals, abs=1e-3) == expected_goals_pts
    assert pytest.approx(exp_goals, abs=1e-2) == 3.37


def test_clean_sheet_points():
    """Spec §4.3: Clean sheet closed-form Poisson expression."""
    history = [
        PlayerMatchHistory(gameweek=i, was_starter=True, minutes=90)
        for i in range(1, 6)
    ]
    pt = calculate_playing_time(
        availability=1.0,
        history=history,
        position="DEF",
        shrinkage_weight=0.0,
    )
    # Defense clean sheet weight is 4.0
    cs_pts = calculate_clean_sheet_points(pt, lambda_conceded=1.0, position="DEF")
    expected_cs = 4.0 * math.exp(-1.0 * (90.0 / 90.0))
    assert pytest.approx(cs_pts, abs=1e-4) == expected_cs

    # FWD gets 0 clean sheet points
    fwd_cs = calculate_clean_sheet_points(pt, lambda_conceded=1.0, position="FWD")
    assert fwd_cs == 0.0


def test_goals_conceded_penalty_truncation():
    """Spec §4.4: Exact Poisson sum for GK and DEF."""
    history = [
        PlayerMatchHistory(gameweek=i, was_starter=True, minutes=90)
        for i in range(1, 6)
    ]
    pt = calculate_playing_time(
        availability=1.0,
        history=history,
        position="DEF",
        shrinkage_weight=0.0,
    )
    gc_penalty = calculate_goals_conceded_penalty(pt, lambda_conceded=1.5, position="DEF")
    assert gc_penalty <= 0.0

    # MID and FWD do not receive goals conceded penalties
    mid_gc = calculate_goals_conceded_penalty(pt, lambda_conceded=1.5, position="MID")
    assert mid_gc == 0.0


def test_outfield_points_non_negative():
    """Spec §4: Outfield points must be non-negative."""
    history = [
        PlayerMatchHistory(gameweek=1, was_starter=True, minutes=90)
    ]
    pt = calculate_playing_time(availability=1.0, history=history, position="FWD")
    components = compute_projection_components(
        pt=pt,
        xg_90=0.0,
        xa_90=0.0,
        lambda_scored=0.5,
        lambda_conceded=3.0,
        mu=1.35,
        position="FWD",
    )
    assert components.expected_points >= 0.0


def test_negative_outfield_points_raises_validation_error():
    """
    Spec §4: Negative outfield points must be rejected (not silently clamped).
    """
    from fpl_lens.engine.components import ProjectionValidationError, validate_projection_output
    from fpl_lens.engine.types import ProjectionComponents

    # Manually constructed invalid negative outfield projection
    invalid_comp = ProjectionComponents(
        exp_appearance=1.0,
        exp_goals=0.0,
        exp_assists=0.0,
        exp_clean_sheet=0.0,
        exp_goals_conceded=0.0,
        exp_dc=0.0,
        exp_bonus=0.0,
        exp_card_penalty=1.5,
        expected_points=-0.5,  # Negative outfield points!
    )

    with pytest.raises(ProjectionValidationError, match="negative expected points"):
        validate_projection_output(invalid_comp, position="MID")


def test_defensive_contributions_empirical_baseline():
    """
    Spec §4.5: P(DC) = Rate_{DC, pos, mins band} (historical, shrunk to pos prior).
    """
    from fpl_lens.engine.components import calculate_defensive_contributions

    history = [
        PlayerMatchHistory(gameweek=1, was_starter=True, minutes=90, defensive_contributions=2),
        PlayerMatchHistory(gameweek=2, was_starter=True, minutes=90, defensive_contributions=1),
        PlayerMatchHistory(gameweek=3, was_starter=True, minutes=90, defensive_contributions=0),
    ]
    pt = calculate_playing_time(availability=1.0, history=history, position="DEF")

    exp_dc = calculate_defensive_contributions(pt, position="DEF", history=history)
    assert exp_dc > 0.0
    assert exp_dc <= 2.0  # Max DC award is 2 points


def test_goals_conceded_penalty_weighting_and_negative_sign():
    """
    Spec §4.4:
    E[GC] = - sum_{s in B,C,D,E} P(S_s) * sum_{k=0}^K floor(k/2) * (lambda_s^k * e^-lambda_s / k!)
    Confirms:
    1. Weighted by P(60+ | start) via P(S_E) = P(Start) * P(60+ | start) vs P(S_D) = P(Start) * (1 - P(60+ | start)).
    2. Returned value carries negative sign (<= 0.0).
    3. Total xP is reduced when adding this term.
    """
    from fpl_lens.engine.types import PlayingTimeScenarios

    # Scenario 1: Starter who plays under 60 mins (P(60+ | start) = 0.0) -> P(S_D) = 1.0, M_sd = 45 mins
    pt_under_60 = PlayingTimeScenarios(
        p_sa=0.0,
        p_sb=0.0,
        p_sc=0.0,
        p_sd=1.0,
        p_se=0.0,
        m_sb=20.0,
        m_sc=65.0,
        m_sd=45.0,
        m_se=90.0,
        expected_minutes=45.0,
        p_start=1.0,
        p_sub=0.0,
        p_60_plus_given_start=0.0,
        p_60_plus_given_sub=0.0,
        availability=1.0,
    )

    # Scenario 2: Starter who plays 60+ mins (P(60+ | start) = 1.0) -> P(S_E) = 1.0, M_se = 90 mins
    pt_60_plus = PlayingTimeScenarios(
        p_sa=0.0,
        p_sb=0.0,
        p_sc=0.0,
        p_sd=0.0,
        p_se=1.0,
        m_sb=20.0,
        m_sc=65.0,
        m_sd=45.0,
        m_se=90.0,
        expected_minutes=90.0,
        p_start=1.0,
        p_sub=0.0,
        p_60_plus_given_start=1.0,
        p_60_plus_given_sub=0.0,
        availability=1.0,
    )

    lambda_conceded = 1.8
    penalty_under_60 = calculate_goals_conceded_penalty(pt_under_60, lambda_conceded, position="DEF")
    penalty_60_plus = calculate_goals_conceded_penalty(pt_60_plus, lambda_conceded, position="DEF")

    # 1. Negative sign confirmed (non-positive)
    assert penalty_under_60 <= 0.0
    assert penalty_60_plus <= 0.0

    # 2. Weighting by P(60+ | start): 90-min starter incurs larger negative penalty than 45-min starter
    assert penalty_60_plus < penalty_under_60
    assert abs(penalty_60_plus) > abs(penalty_under_60)

    # 3. Addition into xP strictly reduces points
    comp_60 = compute_projection_components(
        pt=pt_60_plus,
        xg_90=0.0,
        xa_90=0.0,
        lambda_scored=1.0,
        lambda_conceded=lambda_conceded,
        mu=1.35,
        position="DEF",
        enforce_validation=False,
    )
    assert comp_60.exp_goals_conceded < 0.0
    # Expected points = App (2.0) + CleanSheet + GC (negative) + DC + Bonus - Cards
    assert comp_60.expected_points < 2.0 + comp_60.exp_clean_sheet + comp_60.exp_dc + comp_60.exp_bonus


def test_projection_configured_output_bounds():
    """
    Spec §4 & Implementation Plan:
    Configured bounds on every projection value must be enforced.
    Values exceeding bounds must raise ProjectionValidationError.
    """
    from fpl_lens.engine.components import (
        PROJECTION_BOUNDS,
        ProjectionValidationError,
        validate_projection_output,
    )
    from fpl_lens.engine.types import ProjectionComponents

    # Verify every required component has configured bounds
    expected_fields = [
        "exp_appearance",
        "exp_goals",
        "exp_assists",
        "exp_clean_sheet",
        "exp_goals_conceded",
        "exp_dc",
        "exp_bonus",
        "exp_card_penalty",
        "expected_points_outfield",
        "expected_points_gk",
    ]
    for f in expected_fields:
        assert f in PROJECTION_BOUNDS
        low, high = PROJECTION_BOUNDS[f]
        assert low < high

    # Test out-of-bounds component triggers validation error
    excessive_goals = ProjectionComponents(
        exp_appearance=2.0,
        exp_goals=12.5,  # Exceeds max 10.0
        exp_assists=0.0,
        exp_clean_sheet=0.0,
        exp_goals_conceded=0.0,
        exp_dc=0.0,
        exp_bonus=1.0,
        exp_card_penalty=0.0,
        expected_points=15.5,
    )
    with pytest.raises(ProjectionValidationError, match="outside configured bounds"):
        validate_projection_output(excessive_goals, position="FWD")

