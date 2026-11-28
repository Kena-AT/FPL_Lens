"""
Layer 1 v2 Projection Engine Orchestrator per Engine Design §5.8-§5.11.
Enforces I11 (components sum to xp), I12 (probability partition),
I13 (no zero clamping), I14 (team goal share coherence), and I15 (blank GW).
"""

from __future__ import annotations

import math

from fpl_lens.engine.layer1_v2.availability_v2 import AvailabilityCalibrator
from fpl_lens.engine.layer1_v2.components_v2 import (
    OWN_GOAL_RATE_BY_POS,
    compute_components_v2,
    compute_team_goal_and_assist_shares,
)
from fpl_lens.engine.layer1_v2.playing_time_v2 import (
    IsotonicCalibrator,
    calculate_playing_time_v2,
)
from fpl_lens.engine.layer1_v2.team_model_v2 import PoissonTeamModel
from fpl_lens.engine.layer1_v2.uncertainty_v2 import (
    SplitConformalCalibrator,
    compute_confidence,
)
from fpl_lens.engine.projection import compute_inputs_hash
from fpl_lens.engine.types import (
    FixtureContext,
    FixtureProjectionV2,
    PlayerFeatures,
    ProjectionComponentsV2,
    TeamStrength,
)
from fpl_lens.rules.rules_table import RULES_TABLE_VERSION

MODEL_VERSION_V2 = "xp-2.0.0"
DEFAULT_DGW_ROTATION_FACTOR = 0.94  # [TUNE] §5.10


def _assert_invariants(proj: FixtureProjectionV2) -> None:
    # I11: Components sum to xp within 1e-9
    comp_sum = proj.components.component_sum()
    if abs(comp_sum - proj.xp) > 1e-9:
        raise ValueError(f"I11 violated: sum={comp_sum} vs xp={proj.xp}")
    # I12: Probabilities in [0, 1] and p_start + p_sub + p_zero == 1
    for val in (proj.p_start, proj.p_sub, proj.p_zero, proj.p_play):
        if val < -1e-9 or val > 1.0 + 1e-9:
            raise ValueError(f"I12 probability out of bounds: {val}")
    if abs(proj.p_start + proj.p_sub + proj.p_zero - 1.0) > 1e-9:
        raise ValueError("I12 violated: p_start + p_sub + p_zero != 1")
    # I13: Finite expected points
    if not math.isfinite(proj.xp):
        raise ValueError("I13 violated: non-finite xp")


def run_projection_cycle_v2(
    *,
    gameweek: int,
    players: list[PlayerFeatures],
    fixtures: list[FixtureContext],
    teams: dict[int, TeamStrength],
    team_model: PoissonTeamModel,
    availability_calibrator: AvailabilityCalibrator | None = None,
    conformal_calibrator: SplitConformalCalibrator | None = None,
    start_calibrator: IsotonicCalibrator | None = None,
    p60_calibrator: IsotonicCalibrator | None = None,
    is_stale: bool = False,
    dgw_rotation_factor: float = DEFAULT_DGW_ROTATION_FACTOR,
) -> tuple[list[FixtureProjectionV2], str]:
    """
    Runs Layer 1 v2 across all players and fixtures in `gameweek`.
    Computes team-coherent goal/assist shares per fixture (I14) and emits blank-GW
    projections with label 'No fixture' (I15).
    """
    avail_cal = availability_calibrator or AvailabilityCalibrator()
    conf_cal = conformal_calibrator or SplitConformalCalibrator()
    league_avgs = {"mu": team_model.mu}
    inputs_hash = compute_inputs_hash(gameweek, players, fixtures, teams, league_avgs).hex()

    team_fixtures: dict[int, list[FixtureContext]] = {}
    for f in fixtures:
        if f.gameweek == gameweek:
            team_fixtures.setdefault(f.team_fpl_id, []).append(f)

    # Sort players deterministically by id (§13.3)
    ordered_players = sorted(players, key=lambda p: p.player_fpl_id)
    players_by_team: dict[int, list[PlayerFeatures]] = {}
    for p in ordered_players:
        players_by_team.setdefault(p.team_fpl_id, []).append(p)

    results: list[FixtureProjectionV2] = []

    for team_id in sorted(players_by_team.keys()):
        squad_players = players_by_team[team_id]
        t_fixtures = sorted(team_fixtures.get(team_id, []), key=lambda fx: fx.fixture_fpl_id)

        # Blank gameweek (§5.10, I15)
        if not t_fixtures:
            for p in squad_players:
                zero_comps = ProjectionComponentsV2(
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
                )
                proj = FixtureProjectionV2(
                    player_fpl_id=p.player_fpl_id,
                    fixture_fpl_id=0,
                    gameweek=gameweek,
                    p_start=0.0,
                    p_sub=0.0,
                    p_zero=1.0,
                    p_play=0.0,
                    xp=0.0,
                    xp_given_play=0.0,
                    xp_by_scenario={"S_B": 0.0, "S_C": 0.0, "S_D": 0.0, "S_E": 0.0},
                    components=zero_comps,
                    interval50=(0.0, 0.0),
                    interval80=(0.0, 0.0),
                    confidence="HIGH" if not is_stale else "LOW",
                    confidence_reasons=("snapshot_stale",) if is_stale else (),
                    inputs_hash=inputs_hash,
                    model_version=MODEL_VERSION_V2,
                    rules_version=RULES_TABLE_VERSION,
                    is_calibrated=True,
                    is_blank=True,
                    label="No fixture",
                )
                _assert_invariants(proj)
                results.append(proj)
            continue

        is_dgw = len(t_fixtures) >= 2
        for fix in t_fixtures:
            lam_for, lam_against, low_team_sample = team_model.predict_intensities(
                fix.team_fpl_id, fix.opponent_fpl_id, fix.is_home
            )

            # 1. Compute availability & playing time per player (with DGW rotation factor)
            pt_map = {}
            cal_flags = {}
            raw_goal_w: dict[int, float] = {}
            raw_assist_w: dict[int, float] = {}
            og_expected_total = 0.0

            for p in squad_players:
                alpha, is_cal = avail_cal.predict(
                    p.status,
                    p.chance_of_playing_next_round,
                    news_added_at=p.news_added_at,
                    as_of=p.as_of,
                )
                if is_dgw:
                    alpha *= dgw_rotation_factor
                pt = calculate_playing_time_v2(
                    availability=alpha,
                    history=p.history,
                    target_gameweek=gameweek,
                    position=p.position,
                    start_calibrator=start_calibrator,
                    p60_calibrator=p60_calibrator,
                )
                pt_map[p.player_fpl_id] = pt
                cal_flags[p.player_fpl_id] = is_cal
                mins_frac = pt.expected_minutes / 90.0
                pen_boost = 0.12 if p.is_penalty_taker else 0.0
                raw_goal_w[p.player_fpl_id] = max(0.01, (p.xg_90 + pen_boost) * mins_frac)
                raw_assist_w[p.player_fpl_id] = max(0.01, p.xa_90 * mins_frac)
                og_expected_total += OWN_GOAL_RATE_BY_POS.get(p.position.upper(), 0.003) * (
                    1.0 - pt.p_sa
                )

            # 2. Allocate team-coherent goal & assist shares (I14)
            exp_goals_cnt, exp_assists_cnt = compute_team_goal_and_assist_shares(
                raw_goal_w,
                raw_assist_w,
                lambda_for=lam_for,
                own_goal_expected_total=og_expected_total,
            )

            # 3. Raw bonus scores rescaled to ~3.2 per team (total ~6.0 per match, §5.7)
            raw_bonus = {
                p.player_fpl_id: (
                    0.35 * exp_goals_cnt[p.player_fpl_id]
                    + 0.25 * exp_assists_cnt[p.player_fpl_id]
                    + 0.15 * (1.0 - pt_map[p.player_fpl_id].p_sa)
                )
                for p in squad_players
            }
            bonus_sum = sum(raw_bonus.values())
            bonus_scale = (3.0 / bonus_sum) if bonus_sum > 0 else 0.0

            # 4. Build final FixtureProjectionV2 per player
            for p in squad_players:
                pt = pt_map[p.player_fpl_id]
                comps, xp_given_play, xp_scen = compute_components_v2(
                    pt=pt,
                    position=p.position,
                    lambda_conceded=lam_against,
                    expected_goals_count=exp_goals_cnt[p.player_fpl_id],
                    expected_assists_count=exp_assists_cnt[p.player_fpl_id],
                    history=p.history,
                    is_penalty_taker=p.is_penalty_taker,
                    bonus_override=raw_bonus[p.player_fpl_id] * bonus_scale,
                )
                i50, i80 = conf_cal.predict_intervals(p.position, comps.expected_points)
                conf, reasons = compute_confidence(
                    is_stale=is_stale,
                    sample_matches=len(p.history),
                    interval80=i80,
                    is_availability_calibrated=cal_flags[p.player_fpl_id],
                    low_team_sample=low_team_sample,
                )
                proj = FixtureProjectionV2(
                    player_fpl_id=p.player_fpl_id,
                    fixture_fpl_id=fix.fixture_fpl_id,
                    gameweek=gameweek,
                    p_start=pt.p_start,
                    p_sub=pt.p_sub,
                    p_zero=pt.p_sa,
                    p_play=1.0 - pt.p_sa,
                    xp=comps.expected_points,
                    xp_given_play=xp_given_play,
                    xp_by_scenario=xp_scen,
                    components=comps,
                    interval50=i50,
                    interval80=i80,
                    confidence=conf,
                    confidence_reasons=reasons,
                    inputs_hash=inputs_hash,
                    model_version=MODEL_VERSION_V2,
                    rules_version=RULES_TABLE_VERSION,
                    is_calibrated=cal_flags[p.player_fpl_id],
                )
                _assert_invariants(proj)
                results.append(proj)

    return results, inputs_hash
