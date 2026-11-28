"""
Layer 3 & Chip Validation Helpers per Engine Design §11.4 & §11.5.
"""

from __future__ import annotations

from dataclasses import dataclass

from fpl_lens.engine.layer1_v2.validation_v2 import block_bootstrap_ci


@dataclass(frozen=True)
class Layer3BacktestReport:
    moves_evaluated: int
    mean_realised_net_gain: float
    positive_net_gain_fraction: float
    mean_net_gain_ci: tuple[float, float]
    hits_taken: int
    positive_hit_fraction: float
    shortlist_recall: float
    accepted: bool


def evaluate_layer3_backtest(
    moves: list[tuple[int, float, int]],
    *,
    shortlist_hits: int,
    shortlist_total: int,
) -> Layer3BacktestReport:
    """
    moves: list of (gw, realised_net_gain_after_hit, hit_cost).
    §11.4 Acceptance: lower bound of 4-GW block-bootstrap CI of mean net gain > 0,
    and shortlist recall >= 0.95.
    """
    if not moves:
        return Layer3BacktestReport(0, 0.0, 0.0, (0.0, 0.0), 0, 0.0, 1.0, False)

    by_gw: dict[int, list[float]] = {}
    for gw, net_gain, _ in moves:
        by_gw.setdefault(gw, []).append(net_gain)

    ci = block_bootstrap_ci(by_gw, block_size=4)
    n = len(moves)
    mean_gain = sum(m[1] for m in moves) / n
    pos_frac = sum(1 for m in moves if m[1] > 0.0) / n

    hits = [m for m in moves if m[2] > 0]
    pos_hit_frac = (sum(1 for m in hits if m[1] > 0.0) / len(hits)) if hits else 1.0
    recall = (shortlist_hits / shortlist_total) if shortlist_total > 0 else 1.0

    return Layer3BacktestReport(
        moves_evaluated=n,
        mean_realised_net_gain=mean_gain,
        positive_net_gain_fraction=pos_frac,
        mean_net_gain_ci=ci,
        hits_taken=len(hits),
        positive_hit_fraction=pos_hit_frac,
        shortlist_recall=recall,
        accepted=(ci[0] > 0.0 and recall >= 0.95),
    )


def evaluate_chips_backtest(
    chip_gains: list[float],
    threshold_gains: list[float],
) -> tuple[float, float, bool]:
    """
    §11.5: Counterfactual chip decisions must beat never playing (> 0) and
    beat the legacy fixed-threshold rule on average.
    """
    if not chip_gains:
        return 0.0, 0.0, False
    mean_cf = sum(chip_gains) / len(chip_gains)
    mean_th = sum(threshold_gains) / len(threshold_gains) if threshold_gains else 0.0
    return mean_cf, mean_th, (mean_cf > 0.0 and mean_cf >= mean_th)
