"""
Layer 2 & Layer 3 Backtest Evaluation Helpers per Engine Design §11.3 & §11.4.
"""

from __future__ import annotations

from dataclasses import dataclass

from fpl_lens.engine.layer1_v2.validation_v2 import block_bootstrap_ci


@dataclass(frozen=True)
class Layer2BacktestReport:
    gameweeks_evaluated: int
    mean_engine_xi_points: float
    mean_highest_xp_xi_points: float
    mean_prev_gw_xi_points: float
    mean_oracle_xi_points: float
    mean_regret_vs_oracle: float
    gain_over_prev_gw_ci: tuple[float, float]


def evaluate_layer2_backtest(
    gw_scores: list[tuple[int, float, float, float, float]],
) -> Layer2BacktestReport:
    """
    gw_scores: list of (gw, engine_xi_pts, highest_xp_xi_pts, prev_gw_xi_pts, oracle_xi_pts).
    Computes mean scores, oracle regret, and 4-GW block-bootstrap CI over prev-GW baseline (§11.3).
    """
    if not gw_scores:
        return Layer2BacktestReport(0, 0.0, 0.0, 0.0, 0.0, 0.0, (0.0, 0.0))

    n = len(gw_scores)
    diff_by_gw = {gw: [eng - prev] for gw, eng, _, prev, _ in gw_scores}
    ci = block_bootstrap_ci(diff_by_gw, block_size=4)

    mean_eng = sum(x[1] for x in gw_scores) / n
    mean_hxp = sum(x[2] for x in gw_scores) / n
    mean_prev = sum(x[3] for x in gw_scores) / n
    mean_ora = sum(x[4] for x in gw_scores) / n

    return Layer2BacktestReport(
        gameweeks_evaluated=n,
        mean_engine_xi_points=mean_eng,
        mean_highest_xp_xi_points=mean_hxp,
        mean_prev_gw_xi_points=mean_prev,
        mean_oracle_xi_points=mean_ora,
        mean_regret_vs_oracle=mean_ora - mean_eng,
        gain_over_prev_gw_ci=ci,
    )
