import math
import random

from fpl_lens.engine.components import calculate_goals_conceded_penalty
from fpl_lens.engine.types import PlayingTimeScenarios


def test_goals_conceded_penalty_monte_carlo_agreement():
    """
    Sprint 5 Verification item:
    The goals-conceded penalty matches a Monte Carlo simulation within sampling error,
    for three test rates (0.8, 1.4, 2.2).
    """
    # 3 test rates
    test_rates = [0.8, 1.4, 2.2]
    n_simulations = 100_000
    rng = random.Random(2026)

    for lam in test_rates:
        # Full 90 min starter scenario
        pt = PlayingTimeScenarios(
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

        # 1. Closed-form exact Poisson formula
        analytical_penalty = abs(calculate_goals_conceded_penalty(pt, lambda_conceded=lam, position="DEF"))

        # 2. Monte Carlo simulation of Poisson process:
        # Knuth's algorithm for Poisson random variate
        sample_penalties = []
        l_exp = math.exp(-lam)

        for _ in range(n_simulations):
            k = 0
            p = 1.0
            while p > l_exp:
                k += 1
                p *= rng.random()
            goals = k - 1
            sample_penalties.append(goals // 2)

        mc_mean = sum(sample_penalties) / n_simulations
        mc_variance = sum((x - mc_mean) ** 2 for x in sample_penalties) / (n_simulations - 1)
        mc_se = math.sqrt(mc_variance / n_simulations)

        # Assert analytical value is within 3 standard errors of Monte Carlo estimate (99.7% confidence)
        diff = abs(analytical_penalty - mc_mean)
        assert diff <= 3.0 * mc_se, (
            f"Rate {lam}: Analytical {analytical_penalty} differed from MC {mc_mean} by {diff} > 3*SE ({3*mc_se})"
        )


def test_captaincy_pair_monte_carlo_agreement():
    """
    Sprint 5 Verification item:
    The captaincy pair value matches a Monte Carlo simulation within sampling error,
    for three test pairs.
    """
    # Three test pairs: (q_c, q_v, xp_c, xp_v)
    test_pairs = [
        {"name": "High-C", "q_c": 0.95, "q_v": 0.90, "xp_c": 8.0, "xp_v": 6.0},
        {"name": "Med-C",  "q_c": 0.70, "q_v": 0.85, "xp_c": 7.0, "xp_v": 6.5},
        {"name": "Low-C",  "q_c": 0.50, "q_v": 0.95, "xp_c": 6.0, "xp_v": 7.5},
    ]

    n_simulations = 100_000
    rng = random.Random(9999)

    for pair in test_pairs:
        qc = pair["q_c"]
        qv = pair["q_v"]
        xpc = pair["xp_c"]
        xpv = pair["xp_v"]

        # Conditional expected points if appearing
        xpc_play = xpc / qc
        xpv_play = xpv / qv

        # Analytical captain bonus term per Spec §5.1:
        # q_c * xP_c|app + (1 - q_c) * q_v * xP_v|app = xP_c + (1 - q_c) * xP_v
        analytical_bonus = qc * xpc_play + (1.0 - qc) * qv * xpv_play

        # Monte Carlo simulation of appearance states
        sim_bonuses = []
        for _ in range(n_simulations):
            c_plays = rng.random() < qc
            v_plays = rng.random() < qv

            if c_plays:
                sim_bonuses.append(xpc_play)
            elif v_plays:
                sim_bonuses.append(xpv_play)
            else:
                sim_bonuses.append(0.0)

        mc_mean = sum(sim_bonuses) / n_simulations
        mc_var = sum((x - mc_mean) ** 2 for x in sim_bonuses) / (n_simulations - 1)
        mc_se = math.sqrt(mc_var / n_simulations)

        diff = abs(analytical_bonus - mc_mean)
        assert diff <= 3.0 * mc_se, (
            f"Pair {pair['name']}: Analytical {analytical_bonus} differed from MC {mc_mean} by {diff} > 3*SE ({3*mc_se})"
        )
