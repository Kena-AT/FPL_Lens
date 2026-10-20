import random

import pytest

from fpl_lens.engine.playing_time import calculate_playing_time
from fpl_lens.engine.types import PlayerMatchHistory


def test_scenario_probabilities_sum_to_one_and_non_negative():
    """
    Sprint 5 Verification item:
    Scenario probabilities for every player sum to one, and none is negative.
    Covered by a property-based test over 500 randomized parameter configurations.
    """
    rng = random.Random(1337)
    positions = ["GK", "DEF", "MID", "FWD"]

    for _ in range(500):
        # Random availability in [0.0, 1.0]
        alpha = rng.random()
        pos = rng.choice(positions)

        # Random match history length 0 to 10
        num_matches = rng.randint(0, 10)
        history = []
        for gw in range(1, num_matches + 1):
            started = rng.choice([True, False])
            mins = (
                rng.randint(60, 95)
                if started
                else (rng.randint(0, 45) if rng.random() > 0.3 else 0)
            )
            history.append(
                PlayerMatchHistory(
                    gameweek=gw,
                    was_starter=started,
                    minutes=mins,
                )
            )

        shrinkage = rng.uniform(0.5, 5.0)
        pt = calculate_playing_time(
            availability=alpha,
            history=history,
            position=pos,
            shrinkage_weight=shrinkage,
        )

        # 1. Non-negativity check
        assert pt.p_sa >= -1e-9, f"P(S_A) was negative: {pt.p_sa}"
        assert pt.p_sb >= -1e-9, f"P(S_B) was negative: {pt.p_sb}"
        assert pt.p_sc >= -1e-9, f"P(S_C) was negative: {pt.p_sc}"
        assert pt.p_sd >= -1e-9, f"P(S_D) was negative: {pt.p_sd}"
        assert pt.p_se >= -1e-9, f"P(S_E) was negative: {pt.p_se}"

        # 2. Sum to one check
        prob_sum = pt.p_sa + pt.p_sb + pt.p_sc + pt.p_sd + pt.p_se
        assert pytest.approx(prob_sum, abs=1e-6) == 1.0, f"Sum was {prob_sum}"


def test_p_start_plus_p_sub_bounded_by_alpha():
    """
    Sprint 5 Verification item:
    P(Start) + P(Sub) <= alpha for every player.
    Covered by a property-based test over 500 randomized configurations.
    """
    rng = random.Random(42)
    positions = ["GK", "DEF", "MID", "FWD"]

    for _ in range(500):
        alpha = rng.random()
        pos = rng.choice(positions)
        num_matches = rng.randint(0, 8)
        history = [
            PlayerMatchHistory(
                gameweek=i,
                was_starter=rng.choice([True, False]),
                minutes=rng.randint(0, 90),
            )
            for i in range(1, num_matches + 1)
        ]

        pt = calculate_playing_time(
            availability=alpha,
            history=history,
            position=pos,
        )

        # P(Start) + P(Sub) <= alpha
        appearance_prob = pt.p_start + pt.p_sub
        assert appearance_prob <= alpha + 1e-7, (
            f"P(Start) + P(Sub) = {appearance_prob} exceeded alpha = {alpha}"
        )
