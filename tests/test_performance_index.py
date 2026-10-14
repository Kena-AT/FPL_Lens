"""
Tests for Spec §13A Performance Index (POI).
Verifies determinism, missing data handling, normalisation bounds, and backtest property.
"""

import json
import os
import random

import pytest

from fpl_lens.engine.performance_index import (
    StarterInput,
    calculate_performance_index,
)


def test_performance_index_determinism_and_bounds():
    starters = [
        StarterInput(player_id=i, xp=2.0 + i * 0.5, p_start=0.5 + i * 0.04, form=3.0 + (i % 3), ppg=3.5 + (i % 2))
        for i in range(1, 12)
    ]
    res1 = calculate_performance_index(starters)
    res2 = calculate_performance_index(starters)

    assert res1 is not None
    assert res2 is not None
    assert len(res1) == 11
    assert res1 == res2

    for r in res1:
        assert 0 <= r.poi <= 100
        assert not r.is_partial


def test_performance_index_missing_mandatory_data_returns_none():
    starters = [
        StarterInput(player_id=i, xp=3.0, p_start=0.8, form=4.0, ppg=4.0)
        for i in range(1, 12)
    ]
    # Set one starter's xp to None
    starters[5] = StarterInput(player_id=6, xp=None, p_start=0.8, form=4.0, ppg=4.0)
    assert calculate_performance_index(starters) is None

    # Set one starter's p_start to None
    starters[5] = StarterInput(player_id=6, xp=3.0, p_start=None, form=4.0, ppg=4.0)
    assert calculate_performance_index(starters) is None


def test_performance_index_partial_when_descriptive_missing():
    starters = [
        StarterInput(player_id=i, xp=3.0 + i, p_start=0.8, form=4.0, ppg=4.0)
        for i in range(1, 12)
    ]
    # Missing form for player 3
    starters[2] = StarterInput(player_id=3, xp=5.0, p_start=0.8, form=None, ppg=4.0)
    res = calculate_performance_index(starters)
    assert res is not None
    assert res[2].is_partial is True
    assert res[0].is_partial is False


def test_performance_index_backtest_outscores_chance_over_ten_gameweeks():
    """
    Spec §13A Validation:
    Over at least 10 gameweeks, the top-ranked starters by index must outscore
    the squad average on actual points more often than chance (> 50%).
    """
    fixture_path = "tests/fixtures/fpl_2023_24_real_history.json"
    if not os.path.exists(fixture_path):
        pytest.skip("Historical fixture not found")

    with open(fixture_path, encoding="utf-8") as f:
        players = json.load(f)

    # Use 15 historical gameweeks (GW10 to GW24)
    test_gws = list(range(10, 25))
    assert len(test_gws) >= 10

    # Build predictions
    records_by_gw: dict[int, list[dict]] = {}
    for gw in test_gws:
        for p in players:
            matches = p["matches"]
            prior_matches = [m for m in matches if m["gameweek"] < gw]
            target_match = next((m for m in matches if m["gameweek"] == gw), None)
            if not target_match or not prior_matches:
                continue

            apps = [m for m in prior_matches if m["minutes"] > 0]
            ppg = sum(m["total_points"] for m in apps) / len(apps) if apps else 2.0
            form = sum(m["total_points"] for m in prior_matches[-5:]) / min(5, len(prior_matches))
            recent_mins = sum(m["minutes"] for m in prior_matches[-3:])
            p_start = 0.9 if recent_mins > 180 else (0.5 if recent_mins > 60 else 0.2)
            xp = ppg * (1.1 if target_match["was_home"] else 0.9)

            records_by_gw.setdefault(gw, []).append({
                "id": p["element"],
                "pos": p["position"],
                "team": p["team"],
                "xp": xp,
                "p_start": p_start,
                "form": form,
                "ppg": ppg,
                "actual_pts": int(target_match["total_points"]),
            })

    rng = random.Random(999)
    gws_above_chance = 0

    for gw in test_gws:
        pool = records_by_gw[gw]
        gks = [p for p in pool if p["pos"] == "GK"]
        defs = [p for p in pool if p["pos"] == "DEF"]
        mids = [p for p in pool if p["pos"] == "MID"]
        fwds = [p for p in pool if p["pos"] == "FWD"]

        outscore_count = 0
        trials = 50

        for _ in range(trials):
            squad = rng.sample(gks, 2) + rng.sample(defs, 5) + rng.sample(mids, 5) + rng.sample(fwds, 3)
            # Pick 11 starters (1 GK, 3 DEF, 4 MID, 3 FWD)
            starters = [squad[0]] + squad[2:5] + squad[7:11] + squad[12:15]

            starter_inputs = [
                StarterInput(player_id=p["id"], xp=p["xp"], p_start=p["p_start"], form=p["form"], ppg=p["ppg"])
                for p in starters
            ]
            poi_results = calculate_performance_index(starter_inputs)
            assert poi_results is not None

            # Rank starters by POI
            ranked = sorted(zip(poi_results, starters, strict=False), key=lambda x: x[0].poi, reverse=True)
            top_5 = ranked[:5]

            avg_top = sum(p["actual_pts"] for _, p in top_5) / len(top_5)
            avg_squad = sum(p["actual_pts"] for p in squad) / len(squad)

            if avg_top > avg_squad:
                outscore_count += 1

        if (outscore_count / trials) > 0.50:
            gws_above_chance += 1

    # Over at least 10 gameweeks, must outscore squad average more often than chance (> 50%)
    fraction_above_chance = gws_above_chance / len(test_gws)
    assert fraction_above_chance > 0.50, f"Only {gws_above_chance}/{len(test_gws)} gameweeks outscored chance"
