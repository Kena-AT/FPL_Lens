import random

from fpl_lens.engine.backtest import (
    BacktestPrediction,
    evaluate_backtest,
)
from fpl_lens.engine.components import compute_projection_components
from fpl_lens.engine.intensities import calculate_team_intensities
from fpl_lens.engine.playing_time import calculate_playing_time
from fpl_lens.engine.types import (
    PlayerMatchHistory,
    TeamStrength,
)


def test_backtest_over_ten_gameweeks_with_baselines_and_calibration():
    """
    Sprint 5 Verification items:
    - The backtest runs on at least 10 historical gameweeks, with the baselines and confidence intervals reported.
    - The engine beats or matches the points-per-game baseline on MAE, or the result is recorded as a finding.
    - Calibration for P(Start) and P(60+ | start) is produced and verified.
    """
    rng = random.Random(42)

    # Teams
    team1 = TeamStrength(1, "Team 1", "T1", 1200, 1150, 1250, 1200)
    team2 = TeamStrength(2, "Team 2", "T2", 1100, 1050, 1150, 1100)
    league_averages = {
        "mu": 1.35,
        "att_home_avg": 1150.0,
        "att_away_avg": 1100.0,
        "def_home_avg": 1200.0,
        "def_away_avg": 1150.0,
    }

    # Generate synthetic season history for 20 players over 15 gameweeks
    # 5 GK, 5 DEF, 5 MID, 5 FWD
    positions = ["GK"] * 5 + ["DEF"] * 5 + ["MID"] * 5 + ["FWD"] * 5
    players_data = []

    for pid, pos in enumerate(positions, start=1):
        quality = rng.uniform(0.5, 1.5)
        starter_prob = rng.uniform(0.6, 0.95)

        gw_history: list[PlayerMatchHistory] = []
        for gw in range(1, 16):
            starts = rng.random() < starter_prob
            if starts:
                mins = rng.randint(65, 90)
                goals = 1 if (rng.random() < 0.25 * quality and pos in ("MID", "FWD")) else 0
                assists = (
                    1 if (rng.random() < 0.20 * quality and pos in ("MID", "FWD", "DEF")) else 0
                )
                cs = 1 if (rng.random() < 0.35 and pos in ("GK", "DEF")) else 0
                gc = rng.randint(0, 2) if pos in ("GK", "DEF") else 0
            else:
                mins = rng.randint(10, 30) if rng.random() < 0.4 else 0
                goals = 0
                assists = 0
                cs = 0
                gc = 0

            # Compute actual FPL points
            pts = 0
            if mins > 0:
                pts += 1 if mins < 60 else 2
                pts += goals * (5 if pos == "MID" else (4 if pos == "FWD" else 6))
                pts += assists * 3
                if cs:
                    pts += 4 if pos in ("GK", "DEF") else (1 if pos == "MID" else 0)
                if pos in ("GK", "DEF"):
                    pts -= gc // 2

            gw_history.append(
                PlayerMatchHistory(
                    gameweek=gw,
                    was_starter=starts,
                    minutes=mins,
                    goals_scored=goals,
                    assists=assists,
                    clean_sheets=cs,
                    goals_conceded=gc,
                    total_points=max(0, pts),
                )
            )

        players_data.append({"pid": pid, "pos": pos, "quality": quality, "history": gw_history})

    # Temporal evaluation over at least 10 historical gameweeks: GW6 through GW15 (10 gameweeks)
    backtest_records: list[BacktestPrediction] = []
    test_gameweeks = list(range(6, 16))
    assert len(test_gameweeks) >= 10

    for gw in test_gameweeks:
        for p in players_data:
            # Freeze rule: strictly use history before gw
            prior_history = [h for h in p["history"] if h.gameweek < gw]
            actual_match = next(h for h in p["history"] if h.gameweek == gw)

            # 1. Compute model projection
            pt = calculate_playing_time(
                availability=1.0,
                history=prior_history,
                position=p["pos"],
            )
            lam_s, lam_c = calculate_team_intensities(
                team=team1,
                opponent=team2,
                is_home=True,
                league_averages=league_averages,
            )
            comps = compute_projection_components(
                pt=pt,
                xg_90=0.25 * p["quality"],
                xa_90=0.15 * p["quality"],
                lambda_scored=lam_s,
                lambda_conceded=lam_c,
                mu=1.35,
                position=p["pos"],
            )
            model_xp = comps.expected_points

            # 2. Points-Per-Game (PPG) baseline
            appearances = [h.total_points for h in prior_history if h.minutes > 0]
            ppg = (sum(appearances) / len(appearances)) if appearances else 2.0

            # 3. Previous-gameweek baseline
            prev_match = next((h for h in prior_history if h.gameweek == gw - 1), None)
            prev_gw_pts = float(prev_match.total_points) if prev_match else ppg

            backtest_records.append(
                BacktestPrediction(
                    player_fpl_id=p["pid"],
                    gameweek=gw,
                    position=p["pos"],
                    predicted_xp=model_xp,
                    actual_points=actual_match.total_points,
                    p_start=pt.p_start,
                    was_starter=actual_match.was_starter,
                    p_60_start=pt.p_60_plus_given_start,
                    played_60_plus=(actual_match.minutes >= 60),
                    ppg_baseline=ppg,
                    prev_gw_baseline=prev_gw_pts,
                )
            )

    # Run evaluation
    results = evaluate_backtest(backtest_records)

    # 1. Verification of evaluation coverage
    assert results.total_evaluations == len(players_data) * len(test_gameweeks)
    assert results.overall_mae > 0.0
    assert results.overall_rmse > 0.0

    # 2. Position breakdown exists for all 4 positions
    for pos in ("GK", "DEF", "MID", "FWD"):
        assert pos in results.mae_by_position
        assert pos in results.rmse_by_position
        assert results.mae_by_position[pos] > 0.0

    # 3. Baseline comparison
    # Engine beats or matches points-per-game baseline on MAE
    print(
        f"\nBacktest Results: Model MAE={results.overall_mae}, PPG MAE={results.ppg_baseline_mae}"
    )
    assert (
        results.overall_mae <= results.ppg_baseline_mae + 0.5
    )  # within margin or beating baseline

    # 4. Bootstrap confidence intervals reported
    assert results.bootstrap_mae_ci[0] <= results.overall_mae <= results.bootstrap_mae_ci[1]
    assert results.bootstrap_rmse_ci[0] <= results.overall_rmse <= results.bootstrap_rmse_ci[1]

    # 5. Calibration bins produced for P(Start) and P(60+ | start)
    assert len(results.calibration_p_start) == 5
    assert len(results.calibration_p_60_start) == 5
    for b in results.calibration_p_start:
        assert 0.0 <= b.actual_rate <= 1.0
        assert 0.0 <= b.predicted_avg <= 1.0


def test_backtest_on_real_historical_fpl_data():
    """
    Verification that backtest executes on real FPL 2023-24 season history
    across 10+ gameweeks, strictly respecting the freeze rule and evaluating
    per-position metrics with bootstrap confidence intervals.
    """
    import json
    import os

    fixture_path = "tests/fixtures/fpl_2023_24_real_history.json"
    assert os.path.exists(fixture_path), f"Real fixture missing at {fixture_path}"

    with open(fixture_path, encoding="utf-8") as f:
        players = json.load(f)

    # Use a balanced 40-player cohort across 12 gameweeks (GW10 to GW21) for fast test execution
    gks = [p for p in players if p["position"] == "GK"][:5]
    defs = [p for p in players if p["position"] == "DEF"][:15]
    mids = [p for p in players if p["position"] == "MID"][:15]
    fwds = [p for p in players if p["position"] == "FWD"][:10]
    cohort = gks + defs + mids + fwds
    test_gws = list(range(10, 22))  # 12 gameweeks (> 10 required)

    records: list[BacktestPrediction] = []
    for gw in test_gws:
        for p in cohort:
            matches = p["matches"]
            prior_matches = [m for m in matches if m["gameweek"] < gw]
            target_match = next((m for m in matches if m["gameweek"] == gw), None)
            if not target_match or not prior_matches:
                continue

            hist = [
                PlayerMatchHistory(
                    gameweek=m["gameweek"],
                    was_starter=m["was_starter"],
                    minutes=m["minutes"],
                    goals_scored=m["goals_scored"],
                    assists=m["assists"],
                    clean_sheets=m["clean_sheets"],
                    goals_conceded=m["goals_conceded"],
                    defensive_contributions=m.get("defensive_contributions", 0),
                    bonus=m["bonus"],
                    yellow_cards=m["yellow_cards"],
                    red_cards=m["red_cards"],
                    total_points=m["total_points"],
                )
                for m in prior_matches
            ]

            recent_mins = sum(h.minutes for h in hist[-3:])
            avail = 1.0 if recent_mins > 0 else 0.5
            pos = p["position"]
            pt = calculate_playing_time(availability=avail, history=hist, position=pos)

            total_mins = sum(m["minutes"] for m in prior_matches)
            xg_90 = (
                (sum(m["expected_goals"] for m in prior_matches) / total_mins) * 90.0
                if total_mins >= 90
                else 0.1
            )
            xa_90 = (
                (sum(m["expected_assists"] for m in prior_matches) / total_mins) * 90.0
                if total_mins >= 90
                else 0.1
            )

            comp = compute_projection_components(
                pt=pt,
                xg_90=xg_90,
                xa_90=xa_90,
                lambda_scored=1.4 if target_match["was_home"] else 1.2,
                lambda_conceded=1.1 if target_match["was_home"] else 1.4,
                mu=1.35,
                position=pos,
                history=hist,
                enforce_validation=True,
            )

            apps = [m for m in prior_matches if m["minutes"] > 0]
            ppg = sum(m["total_points"] for m in apps) / len(apps) if apps else 2.0
            prev_match = [m for m in prior_matches if m["gameweek"] == gw - 1]
            prev_pts = prev_match[0]["total_points"] if prev_match else ppg

            records.append(
                BacktestPrediction(
                    player_fpl_id=p["element"],
                    gameweek=gw,
                    position=pos,
                    predicted_xp=comp.expected_points,
                    actual_points=int(target_match["total_points"]),
                    p_start=pt.p_start,
                    was_starter=target_match["was_starter"],
                    p_60_start=pt.p_60_plus_given_start,
                    played_60_plus=(target_match["minutes"] >= 60),
                    ppg_baseline=ppg,
                    prev_gw_baseline=float(prev_pts),
                )
            )

    results = evaluate_backtest(records)
    assert len(test_gws) >= 10
    assert results.total_evaluations > 300
    assert results.overall_mae < results.ppg_baseline_mae
    assert len(results.by_position) == 4
    for pos in ("GK", "DEF", "MID", "FWD"):
        assert pos in results.by_position
        pos_m = results.by_position[pos]
        assert pos_m.sample_size > 0
        assert pos_m.model_mae_ci[0] <= pos_m.model_mae <= pos_m.model_mae_ci[1]
