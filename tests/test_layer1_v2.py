from datetime import UTC, datetime, timedelta

from fpl_lens.engine.layer1_v2.availability_v2 import AvailabilityCalibrator
from fpl_lens.engine.layer1_v2.playing_time_v2 import (
    IsotonicCalibrator,
    calculate_playing_time_v2,
    filter_available_history,
)
from fpl_lens.engine.layer1_v2.projection_v2 import MODEL_VERSION_V2, run_projection_cycle_v2
from fpl_lens.engine.layer1_v2.team_model_v2 import CompletedMatch, PoissonTeamModel
from fpl_lens.engine.layer1_v2.uncertainty_v2 import SplitConformalCalibrator
from fpl_lens.engine.layer1_v2.validation_v2 import (
    compare_champion_challenger,
    compute_brier_score,
    compute_ece,
    evaluate_interval_coverage,
)
from fpl_lens.engine.types import (
    FixtureContext,
    PlayerFeatures,
    PlayerMatchHistory,
    TeamStrength,
)


def _make_history(gws: list[tuple[int, int, bool, int]]) -> list[PlayerMatchHistory]:
    return [
        PlayerMatchHistory(gameweek=gw, was_starter=st, minutes=mins, saves=sv)
        for gw, mins, st, sv in gws
    ]


def test_availability_calibrator_fallback_and_empirical():
    now = datetime(2026, 11, 27, 12, 0, tzinfo=UTC)
    obs = [("d", 75, "0_24h", i < 18) for i in range(25)]
    cal = AvailabilityCalibrator.fit(obs, min_cell_count=20)

    alpha_cal, is_cal = cal.predict("d", 75, news_added_at=now - timedelta(hours=4), as_of=now)
    assert is_cal is True
    assert 0.65 < alpha_cal < 0.80

    # Unseen cell falls back to uncalibrated FPL value
    alpha_raw, is_cal_raw = cal.predict("d", 25, news_added_at=now - timedelta(hours=4), as_of=now)
    assert is_cal_raw is False
    assert alpha_raw == 0.25


def test_unavailable_spell_exclusion_and_isotonic_pava():
    # Player had a 4-GW injury spell (0 mins) followed by 3 starts
    hist = _make_history([
        (1, 90, True, 0),
        (2, 0, False, 0),
        (3, 0, False, 0),
        (4, 0, False, 0),
        (5, 0, False, 0),
        (6, 88, True, 0),
        (7, 90, True, 0),
    ])
    filtered = filter_available_history(hist, min_unavailable_spell=3)
    assert [h.gameweek for h in filtered] == [1, 6, 7]

    pt = calculate_playing_time_v2(
        availability=1.0,
        history=hist,
        target_gameweek=8,
        position="MID",
    )
    assert abs(pt.p_start + pt.p_sub + pt.p_sa - 1.0) < 1e-9
    assert pt.p_start > 0.70  # Injury spell did not drag start rate down

    # Isotonic regression reduces ECE on miscalibrated probabilities
    raw_probs = [0.2] * 30 + [0.6] * 30 + [0.9] * 30
    outcomes = ([True] * 12 + [False] * 18) + ([True] * 25 + [False] * 5) + ([True] * 28 + [False] * 2)
    iso = IsotonicCalibrator.fit(raw_probs, outcomes)
    cal_probs = [iso.predict(p) for p in raw_probs]
    assert compute_ece(cal_probs, outcomes, num_bins=5) <= compute_ece(raw_probs, outcomes, num_bins=5)


def test_poisson_team_model_reflects_team_strength_and_home_advantage():
    matches = []
    for gw in range(1, 11):
        matches.append(CompletedMatch(gw, home_team_id=1, away_team_id=2, home_goals=3, away_goals=0))
        matches.append(CompletedMatch(gw, home_team_id=2, away_team_id=1, home_goals=0, away_goals=2))
    model = PoissonTeamModel.fit(matches, current_gameweek=11)
    lam_for_strong, lam_ag_strong, low = model.predict_intensities(1, 2, is_home=True)
    lam_for_weak, _, _ = model.predict_intensities(2, 1, is_home=False)
    assert not low
    assert lam_for_strong > lam_for_weak
    assert lam_for_strong > lam_ag_strong


def test_projection_cycle_v2_invariants_saves_shares_and_blank_gw():
    teams = {
        1: TeamStrength(1, "Strong FC", "STR", 1300, 1250, 1300, 1250),
        2: TeamStrength(2, "Weak FC", "WEK", 1000, 950, 1000, 950),
        3: TeamStrength(3, "Blank FC", "BLK", 1100, 1100, 1100, 1100),
    }
    matches = [
        CompletedMatch(gw, 1, 2, 2, 1) for gw in range(1, 6)
    ] + [
        CompletedMatch(gw, 2, 1, 0, 2) for gw in range(1, 6)
    ]
    team_model = PoissonTeamModel.fit(matches, current_gameweek=6)

    players = [
        PlayerFeatures(1, "GK", "a", 100, 1, 0.0, 0.0, history=_make_history([(5, 90, True, 4)])),
        PlayerFeatures(2, "DEF", "a", 100, 1, 0.08, 0.12, history=_make_history([(5, 90, True, 0)])),
        PlayerFeatures(3, "MID", "a", 100, 1, 0.35, 0.30, history=_make_history([(5, 90, True, 0)])),
        PlayerFeatures(4, "FWD", "a", 100, 1, 0.65, 0.15, is_penalty_taker=True, history=_make_history([(5, 90, True, 0)])),
        # Blank GW player
        PlayerFeatures(5, "MID", "a", 100, 3, 0.25, 0.25, history=_make_history([(5, 90, True, 0)])),
    ]
    fixtures = [FixtureContext(fixture_fpl_id=101, gameweek=6, team_fpl_id=1, opponent_fpl_id=2, is_home=True)]

    projs, _ = run_projection_cycle_v2(
        gameweek=6,
        players=players,
        fixtures=fixtures,
        teams=teams,
        team_model=team_model,
    )
    by_id = {p.player_fpl_id: p for p in projs}

    # GK has non-zero save points & penalty save points
    gk = by_id[1]
    assert gk.model_version == MODEL_VERSION_V2
    assert gk.components.exp_saves > 0.0
    assert gk.components.exp_penalty_saves > 0.0
    assert abs(gk.components.component_sum() - gk.xp) < 1e-9

    # Team goal share coherence (I14)
    lam_for, _, _ = team_model.predict_intensities(1, 2, is_home=True)
    total_exp_goals = (
        by_id[1].components.exp_goals / 10.0
        + by_id[2].components.exp_goals / 6.0
        + by_id[3].components.exp_goals / 5.0
        + by_id[4].components.exp_goals / 4.0
        + sum(-by_id[pid].components.exp_own_goals / 2.0 for pid in (1, 2, 3, 4))
    )
    assert abs(total_exp_goals - lam_for) < 1e-6

    # Blank GW (I15)
    blank = by_id[5]
    assert blank.is_blank is True
    assert blank.xp == 0.0
    assert blank.label == "No fixture"


def test_split_conformal_coverage_and_champion_challenger_block_bootstrap():
    # Generate 210 synthetic calibration residuals across 21 distinct levels
    cal_records = [("MID", 4.0, 4.0 + ((i % 21) - 10) * 0.5) for i in range(210)]
    conf = SplitConformalCalibrator.fit(cal_records)
    intervals_80 = [conf.predict_intervals("MID", 4.0)[1] for _ in range(210)]
    actuals = [4.0 + ((i % 21) - 10) * 0.5 for i in range(210)]
    cov80 = evaluate_interval_coverage(intervals_80, actuals)
    assert 0.77 <= cov80 <= 0.83

    gws = [gw for gw in range(1, 13) for _ in range(10)]
    actual_pts = [4.0] * 120
    champ_preds = [6.0] * 120  # MAE 2.0
    chall_preds = [4.5] * 120  # MAE 0.5
    report = compare_champion_challenger(
        gws=gws,
        champion_preds=champ_preds,
        challenger_preds=chall_preds,
        actuals=actual_pts,
        champion_p_start=[0.8] * 120,
        challenger_p_start=[0.9] * 120,
        was_starter=[True] * 120,
    )
    assert report.promoted is True
    assert report.mae_improvement_ci[0] > 0.0
    assert compute_brier_score([0.9], [True]) < compute_brier_score([0.5], [True])
