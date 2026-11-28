"""
Layer 1 v2 12-component expected points & team-coherent goal/assist shares (§5.4-§5.8).
Enforces I11 (components sum to xp), I13 (no clamping to zero), and I14 (team goal sum).
"""

from __future__ import annotations

import math

from fpl_lens.engine.components import (
    BONUS_RATES,
    CARD_RATES,
    CLEAN_SHEET_WEIGHTS,
    GOAL_WEIGHTS,
    calculate_appearance_points,
    calculate_card_penalty,
    calculate_clean_sheet_points,
    calculate_defensive_contributions,
    calculate_goals_conceded_penalty,
)
from fpl_lens.engine.types import PlayerMatchHistory, PlayingTimeScenarios, ProjectionComponentsV2

OWN_GOAL_RATE_BY_POS = {"GK": 0.002, "DEF": 0.010, "MID": 0.003, "FWD": 0.001}
PENALTY_AGAINST_RATE = 0.095  # Approx PL penalties conceded per team match
GK_PENALTY_SAVE_PROB = 0.16
PENALTY_MISS_BASE_RATE = 0.004
PENALTY_TAKER_MISS_RATE = 0.025


def calculate_gk_save_points(
    pt: PlayingTimeScenarios,
    lambda_saves_per_90: float,
    position: str,
    tail_tolerance: float = 1e-6,
) -> float:
    """
    §5.6: E[SavePts] = sum_{s in B..E} P(S_s) * sum_{k>=0} floor(k/3) * Poisson(k; lam_saves * M_s/90).
    """
    if position.upper() != "GK" or lambda_saves_per_90 <= 0.0:
        return 0.0

    total = 0.0
    for p_s, m_s in (
        (pt.p_sb, pt.m_sb),
        (pt.p_sc, pt.m_sc),
        (pt.p_sd, pt.m_sd),
        (pt.p_se, pt.m_se),
    ):
        if p_s <= 0.0 or m_s <= 0.0:
            continue
        lam = lambda_saves_per_90 * (m_s / 90.0)
        term = math.exp(-lam)
        prob_sum = 0.0
        scen_pts = 0.0
        k = 0
        while True:
            prob_sum += term
            scen_pts += (k // 3) * term
            k += 1
            term = term * lam / k
            if 1.0 - prob_sum < tail_tolerance or k > 30:
                break
        total += p_s * scen_pts
    return total


def estimate_gk_saves_per_90(
    history: list[PlayerMatchHistory],
    lambda_conceded: float,
    prior_saves_per_90: float = 2.9,
    kappa: float = 4.0,
) -> float:
    apps = [h for h in history if h.minutes > 0]
    total_mins = sum(h.minutes for h in apps)
    total_saves = sum(h.saves for h in apps)
    emp = (total_saves / (total_mins / 90.0)) if total_mins > 0 else prior_saves_per_90
    w = len(apps) / (len(apps) + kappa)
    base = w * emp + (1.0 - w) * prior_saves_per_90
    # Slight scaling with opponent attacking intensity
    return max(0.5, base * (0.75 + 0.25 * (lambda_conceded / 1.35)))


def compute_team_goal_and_assist_shares(
    raw_goal_weights: dict[int, float],
    raw_assist_weights: dict[int, float],
    lambda_for: float,
    own_goal_expected_total: float = 0.03,
) -> tuple[dict[int, float], dict[int, float]]:
    """
    §5.4 & I14: Normalizes player goal shares so sum_p E[Goals_p] + E[OG] == lambda_for.
    """
    target_player_goals = max(0.0, lambda_for - own_goal_expected_total)
    total_gw = sum(max(0.0, v) for v in raw_goal_weights.values())
    total_aw = sum(max(0.0, v) for v in raw_assist_weights.values())

    exp_goals: dict[int, float] = {}
    for pid, w in raw_goal_weights.items():
        share = (max(0.0, w) / total_gw) if total_gw > 0 else 0.0
        exp_goals[pid] = target_player_goals * share

    target_assists = target_player_goals * 0.72
    exp_assists: dict[int, float] = {}
    for pid, w in raw_assist_weights.items():
        share = (max(0.0, w) / total_aw) if total_aw > 0 else 0.0
        exp_assists[pid] = target_assists * share

    return exp_goals, exp_assists


def compute_components_v2(
    *,
    pt: PlayingTimeScenarios,
    position: str,
    lambda_conceded: float,
    expected_goals_count: float,
    expected_assists_count: float,
    history: list[PlayerMatchHistory],
    is_penalty_taker: bool = False,
    bonus_override: float | None = None,
) -> tuple[ProjectionComponentsV2, float, dict[str, float]]:
    """
    Computes all 12 signed components, xp_given_play, and xp_by_scenario (S_B..S_E).
    Never clamps expected_points to zero (I13).
    """
    pos = position.upper()
    p_play = 1.0 - pt.p_sa

    exp_app = calculate_appearance_points(pt)
    w_goal = GOAL_WEIGHTS.get(pos, 4.0)
    exp_goals = expected_goals_count * w_goal
    exp_assists = expected_assists_count * 3.0
    exp_cs = calculate_clean_sheet_points(pt, lambda_conceded, pos)
    exp_gc = calculate_goals_conceded_penalty(pt, lambda_conceded, pos)

    lam_saves = estimate_gk_saves_per_90(history, lambda_conceded) if pos == "GK" else 0.0
    exp_saves = calculate_gk_save_points(pt, lam_saves, pos)
    exp_pen_saves = (5.0 * PENALTY_AGAINST_RATE * GK_PENALTY_SAVE_PROB * p_play) if pos == "GK" else 0.0
    miss_rate = PENALTY_TAKER_MISS_RATE if is_penalty_taker else PENALTY_MISS_BASE_RATE
    exp_pen_misses = -2.0 * miss_rate * p_play
    exp_own_goals = -2.0 * OWN_GOAL_RATE_BY_POS.get(pos, 0.003) * p_play

    exp_dc = calculate_defensive_contributions(pt, pos, history=history)
    exp_bonus = bonus_override if bonus_override is not None else BONUS_RATES.get(pos, 0.25) * p_play
    exp_cards = -abs(calculate_card_penalty(pt, pos))

    xp = (
        exp_app
        + exp_goals
        + exp_assists
        + exp_cs
        + exp_gc
        + exp_saves
        + exp_pen_saves
        + exp_pen_misses
        + exp_own_goals
        + exp_dc
        + exp_bonus
        + exp_cards
    )

    xp_given_play = (xp / p_play) if p_play > 1e-6 else 0.0

    # Per-scenario points conditional on that scenario occurring (§5.8)
    e_mins = max(1.0, pt.expected_minutes)
    w_cs = CLEAN_SHEET_WEIGHTS.get(pos, 0.0)
    rate_cards = -(CARD_RATES.get(pos, {"yellow": 0.1, "red": 0.003})["yellow"] + 3.0 * CARD_RATES.get(pos, {"yellow": 0.1, "red": 0.003})["red"])
    xp_by_scenario: dict[str, float] = {}
    for s_key, m_s, app_pts, is_60 in (
        ("S_B", pt.m_sb, 1.0, False),
        ("S_C", pt.m_sc, 2.0, True),
        ("S_D", pt.m_sd, 1.0, False),
        ("S_E", pt.m_se, 2.0, True),
    ):
        frac = m_s / e_mins if p_play > 1e-6 else 0.0
        cs_s = (w_cs * math.exp(-lambda_conceded * (m_s / 90.0))) if is_60 and w_cs > 0 else 0.0
        xp_by_scenario[s_key] = (
            app_pts
            + (exp_goals + exp_assists + exp_saves + exp_bonus) * frac
            + cs_s
            + (exp_gc * frac)
            + (exp_dc / p_play if p_play > 1e-6 else 0.0)
            + rate_cards
        )

    comps = ProjectionComponentsV2(
        exp_appearance=exp_app,
        exp_goals=exp_goals,
        exp_assists=exp_assists,
        exp_clean_sheet=exp_cs,
        exp_goals_conceded=exp_gc,
        exp_saves=exp_saves,
        exp_penalty_saves=exp_pen_saves,
        exp_penalty_misses=exp_pen_misses,
        exp_own_goals=exp_own_goals,
        exp_dc=exp_dc,
        exp_bonus=exp_bonus,
        exp_card_penalty=exp_cards,
        expected_points=xp,
    )
    return comps, xp_given_play, xp_by_scenario
