"""
Validation, 4-GW Block Bootstrap, Calibration Metrics, and Champion/Challenger
harness per Engine Design §11.1, §11.2, §11.8.
"""

from __future__ import annotations

import math
import random
from dataclasses import dataclass


def compute_brier_score(probs: list[float], outcomes: list[bool]) -> float:
    if not probs:
        return 0.0
    return sum((p - (1.0 if o else 0.0)) ** 2 for p, o in zip(probs, outcomes, strict=True)) / len(
        probs
    )


def compute_log_loss(probs: list[float], outcomes: list[bool], eps: float = 1e-6) -> float:
    if not probs:
        return 0.0
    total = 0.0
    for p, o in zip(probs, outcomes, strict=True):
        pc = max(eps, min(1.0 - eps, p))
        total += -math.log(pc) if o else -math.log(1.0 - pc)
    return total / len(probs)


def compute_ece(probs: list[float], outcomes: list[bool], num_bins: int = 10) -> float:
    """Expected Calibration Error across equal-width probability bins (§11.2)."""
    if not probs:
        return 0.0
    n = len(probs)
    ece = 0.0
    step = 1.0 / num_bins
    for b in range(num_bins):
        lo = b * step
        hi = (b + 1) * step
        indices = [
            i
            for i, p in enumerate(probs)
            if (lo <= p <= hi if b == num_bins - 1 else lo <= p < hi)
        ]
        if not indices:
            continue
        avg_p = sum(probs[i] for i in indices) / len(indices)
        avg_y = sum(1.0 if outcomes[i] else 0.0 for i in indices) / len(indices)
        ece += (len(indices) / n) * abs(avg_p - avg_y)
    return ece


def block_bootstrap_ci(
    values_by_gw: dict[int, list[float]],
    *,
    block_size: int = 4,
    n_boot: int = 400,
    seed: int = 42,
) -> tuple[float, float]:
    """
    4-GW block bootstrap CI per Engine Design §11.1 (accounts for cross-GW correlation).
    """
    gws = sorted(values_by_gw.keys())
    if not gws:
        return (0.0, 0.0)
    rng = random.Random(seed)
    blocks = [gws[i : i + block_size] for i in range(max(1, len(gws) - block_size + 1))]
    n_blocks_needed = max(1, math.ceil(len(gws) / block_size))

    boot_means: list[float] = []
    for _ in range(n_boot):
        sample_vals: list[float] = []
        for _ in range(n_blocks_needed):
            blk = rng.choice(blocks)
            for gw in blk:
                sample_vals.extend(values_by_gw[gw])
        if sample_vals:
            boot_means.append(sum(sample_vals) / len(sample_vals))

    if not boot_means:
        return (0.0, 0.0)
    boot_means.sort()
    lo_idx = max(0, int(0.025 * len(boot_means)))
    hi_idx = min(len(boot_means) - 1, int(0.975 * len(boot_means)))
    return boot_means[lo_idx], boot_means[hi_idx]


def evaluate_interval_coverage(
    intervals: list[tuple[float, float]],
    actuals: list[float],
) -> float:
    if not intervals:
        return 0.0
    covered = sum(
        1 for (lo, hi), y in zip(intervals, actuals, strict=True) if lo <= y <= hi
    )
    return covered / len(intervals)


@dataclass(frozen=True)
class ChampionChallengerReport:
    champion_mae: float
    challenger_mae: float
    mae_improvement_ci: tuple[float, float]  # (champion_err - challenger_err)
    promoted: bool
    champion_brier_start: float
    challenger_brier_start: float
    challenger_ece_start: float


def compare_champion_challenger(
    *,
    gws: list[int],
    champion_preds: list[float],
    challenger_preds: list[float],
    actuals: list[float],
    champion_p_start: list[float],
    challenger_p_start: list[float],
    was_starter: list[bool],
) -> ChampionChallengerReport:
    """
    §11.8: Challenger is promoted only if the lower bound of its MAE improvement
    (champion_abs_err - challenger_abs_err) block-bootstrap CI is > 0.
    """
    champ_errs = [abs(p - y) for p, y in zip(champion_preds, actuals, strict=True)]
    chall_errs = [abs(p - y) for p, y in zip(challenger_preds, actuals, strict=True)]

    diff_by_gw: dict[int, list[float]] = {}
    for gw, ce, ne in zip(gws, champ_errs, chall_errs, strict=True):
        diff_by_gw.setdefault(gw, []).append(ce - ne)

    ci = block_bootstrap_ci(diff_by_gw, block_size=4)
    champ_mae = sum(champ_errs) / max(1, len(champ_errs))
    chall_mae = sum(chall_errs) / max(1, len(chall_errs))

    return ChampionChallengerReport(
        champion_mae=champ_mae,
        challenger_mae=chall_mae,
        mae_improvement_ci=ci,
        promoted=ci[0] > 0.0,
        champion_brier_start=compute_brier_score(champion_p_start, was_starter),
        challenger_brier_start=compute_brier_score(challenger_p_start, was_starter),
        challenger_ece_start=compute_ece(challenger_p_start, was_starter),
    )
