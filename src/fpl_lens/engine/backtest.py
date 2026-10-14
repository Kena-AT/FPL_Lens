"""
Temporal backtesting harness, baselines, and evaluation metrics per Technical Spec §12.
"""

import math
import random
from dataclasses import dataclass, field


@dataclass
class BacktestPrediction:
    player_fpl_id: int
    gameweek: int
    position: str
    predicted_xp: float
    actual_points: int
    p_start: float
    was_starter: bool
    p_60_start: float
    played_60_plus: bool
    ppg_baseline: float
    prev_gw_baseline: float


@dataclass
class PositionMetrics:
    sample_size: int
    model_mae: float
    model_mae_ci: tuple[float, float]
    ppg_mae: float
    ppg_mae_ci: tuple[float, float]
    prev_gw_mae: float
    prev_gw_mae_ci: tuple[float, float]
    model_rmse: float
    ppg_rmse: float


@dataclass
class CalibrationBin:
    bin_range: tuple[float, float]
    predicted_avg: float
    actual_rate: float
    count: int


@dataclass
class BacktestResults:
    total_evaluations: int
    overall_mae: float
    overall_rmse: float
    mae_by_position: dict[str, float]
    rmse_by_position: dict[str, float]
    ppg_baseline_mae: float
    prev_gw_baseline_mae: float
    captain_hit_rate: float
    bootstrap_mae_ci: tuple[float, float]
    bootstrap_rmse_ci: tuple[float, float]
    ppg_mae_ci: tuple[float, float] = (0.0, 0.0)
    prev_gw_mae_ci: tuple[float, float] = (0.0, 0.0)
    by_position: dict[str, PositionMetrics] = field(default_factory=dict)
    calibration_p_start: list[CalibrationBin] = field(default_factory=list)
    calibration_p_60_start: list[CalibrationBin] = field(default_factory=list)



def compute_mae(predictions: list[float], actuals: list[float]) -> float:
    """Mean Absolute Error."""
    if not predictions:
        return 0.0
    return sum(abs(p - a) for p, a in zip(predictions, actuals, strict=False)) / len(predictions)


def compute_rmse(predictions: list[float], actuals: list[float]) -> float:
    """Root Mean Squared Error."""
    if not predictions:
        return 0.0
    mse = sum((p - a) ** 2 for p, a in zip(predictions, actuals, strict=False)) / len(predictions)
    return math.sqrt(mse)


def compute_calibration_bins(
    probs: list[float],
    outcomes: list[bool],
    num_bins: int = 5,
) -> list[CalibrationBin]:
    """Computes calibration bins for probability predictions against binary outcomes."""
    bins: list[CalibrationBin] = []
    step = 1.0 / num_bins

    for b in range(num_bins):
        low = b * step
        high = (b + 1) * step
        bin_probs: list[float] = []
        bin_outcomes: list[int] = []

        for p, o in zip(probs, outcomes, strict=False):
            if b == num_bins - 1:
                in_bin = low <= p <= high
            else:
                in_bin = low <= p < high

            if in_bin:
                bin_probs.append(p)
                bin_outcomes.append(1 if o else 0)

        count = len(bin_probs)
        pred_avg = sum(bin_probs) / count if count > 0 else (low + high) / 2.0
        act_rate = sum(bin_outcomes) / count if count > 0 else 0.0

        bins.append(
            CalibrationBin(
                bin_range=(round(low, 2), round(high, 2)),
                predicted_avg=round(pred_avg, 3),
                actual_rate=round(act_rate, 3),
                count=count,
            )
        )

    return bins


def compute_bootstrap_ci(
    errors: list[float],
    metric_fn,
    num_bootstrap: int = 1000,
    confidence_level: float = 0.95,
    seed: int = 42,
) -> tuple[float, float]:
    """Computes non-parametric bootstrap confidence interval for a metric."""
    if not errors:
        return (0.0, 0.0)

    n = len(errors)
    rng = random.Random(seed)
    boot_stats: list[float] = []

    for _ in range(num_bootstrap):
        resample = [errors[rng.randrange(n)] for _ in range(n)]
        boot_stats.append(metric_fn(resample))

    boot_stats.sort()
    alpha = 1.0 - confidence_level
    low_idx = int((alpha / 2.0) * num_bootstrap)
    high_idx = int((1.0 - alpha / 2.0) * num_bootstrap)

    return (round(boot_stats[low_idx], 3), round(boot_stats[high_idx], 3))


def evaluate_backtest(records: list[BacktestPrediction]) -> BacktestResults:
    """
    Evaluates backtest predictions against actual points and baselines per Spec §12.
    """
    if not records:
        return BacktestResults(
            total_evaluations=0,
            overall_mae=0.0,
            overall_rmse=0.0,
            mae_by_position={},
            rmse_by_position={},
            ppg_baseline_mae=0.0,
            prev_gw_baseline_mae=0.0,
            captain_hit_rate=0.0,
            bootstrap_mae_ci=(0.0, 0.0),
            bootstrap_rmse_ci=(0.0, 0.0),
        )

    preds = [r.predicted_xp for r in records]
    actuals = [float(r.actual_points) for r in records]
    ppg_preds = [r.ppg_baseline for r in records]
    prev_preds = [r.prev_gw_baseline for r in records]

    # Overall metrics
    overall_mae = compute_mae(preds, actuals)
    overall_rmse = compute_rmse(preds, actuals)
    ppg_mae = compute_mae(ppg_preds, actuals)
    prev_gw_mae = compute_mae(prev_preds, actuals)

    # Bootstrap confidence intervals for baselines
    ppg_errors = [abs(p - a) for p, a in zip(ppg_preds, actuals, strict=False)]
    prev_errors = [abs(p - a) for p, a in zip(prev_preds, actuals, strict=False)]
    boot_ppg_ci = compute_bootstrap_ci(ppg_errors, lambda errs: sum(errs) / len(errs))
    boot_prev_ci = compute_bootstrap_ci(prev_errors, lambda errs: sum(errs) / len(errs))

    # Metrics by position with bootstrap CIs
    mae_by_pos: dict[str, float] = {}
    rmse_by_pos: dict[str, float] = {}
    by_position: dict[str, PositionMetrics] = {}

    for pos in ("GK", "DEF", "MID", "FWD"):
        pos_records = [r for r in records if r.position.upper() == pos]
        if pos_records:
            pos_preds = [r.predicted_xp for r in pos_records]
            pos_acts = [float(r.actual_points) for r in pos_records]
            pos_ppg = [r.ppg_baseline for r in pos_records]
            pos_prev = [r.prev_gw_baseline for r in pos_records]

            p_mae = compute_mae(pos_preds, pos_acts)
            p_rmse = compute_rmse(pos_preds, pos_acts)
            ppg_m = compute_mae(pos_ppg, pos_acts)
            ppg_r = compute_rmse(pos_ppg, pos_acts)
            prev_m = compute_mae(pos_prev, pos_acts)

            pos_errs = [abs(p - a) for p, a in zip(pos_preds, pos_acts, strict=False)]
            pos_ppg_errs = [abs(p - a) for p, a in zip(pos_ppg, pos_acts, strict=False)]
            pos_prev_errs = [abs(p - a) for p, a in zip(pos_prev, pos_acts, strict=False)]

            pos_mae_ci = compute_bootstrap_ci(pos_errs, lambda errs: sum(errs) / len(errs))
            pos_ppg_ci = compute_bootstrap_ci(pos_ppg_errs, lambda errs: sum(errs) / len(errs))
            pos_prev_ci = compute_bootstrap_ci(pos_prev_errs, lambda errs: sum(errs) / len(errs))

            mae_by_pos[pos] = round(p_mae, 3)
            rmse_by_pos[pos] = round(p_rmse, 3)

            by_position[pos] = PositionMetrics(
                sample_size=len(pos_records),
                model_mae=round(p_mae, 3),
                model_mae_ci=pos_mae_ci,
                ppg_mae=round(ppg_m, 3),
                ppg_mae_ci=pos_ppg_ci,
                prev_gw_mae=round(prev_m, 3),
                prev_gw_mae_ci=pos_prev_ci,
                model_rmse=round(p_rmse, 3),
                ppg_rmse=round(ppg_r, 3),
            )

    # Captain hit rate: for each GW, check if highest predicted xP finished in top 30% of scorers
    gw_map: dict[int, list[BacktestPrediction]] = {}
    for r in records:
        gw_map.setdefault(r.gameweek, []).append(r)

    captain_hits = 0
    total_gws = len(gw_map)

    for _, gw_recs in gw_map.items():
        if not gw_recs:
            continue
        sorted_by_xp = sorted(gw_recs, key=lambda x: x.predicted_xp, reverse=True)
        chosen_captain = sorted_by_xp[0]

        played = [r.actual_points for r in gw_recs if r.actual_points > 0]
        if played:
            played.sort(reverse=True)
            top_30_cutoff = played[max(0, int(len(played) * 0.30) - 1)]
            if chosen_captain.actual_points >= top_30_cutoff:
                captain_hits += 1

    captain_hit_rate = (captain_hits / total_gws) if total_gws > 0 else 0.0

    # Overall bootstrap confidence intervals
    abs_errors = [abs(p - a) for p, a in zip(preds, actuals, strict=False)]
    sq_errors = [(p - a) ** 2 for p, a in zip(preds, actuals, strict=False)]
    boot_mae_ci = compute_bootstrap_ci(abs_errors, lambda errs: sum(errs) / len(errs))
    boot_rmse_ci = compute_bootstrap_ci(sq_errors, lambda errs: math.sqrt(sum(errs) / len(errs)))

    # Calibration of P(Start) and P(60+ | start)
    p_starts = [r.p_start for r in records]
    was_starters = [r.was_starter for r in records]
    cal_p_start = compute_calibration_bins(p_starts, was_starters)

    starter_recs = [r for r in records if r.was_starter]
    p_60_starts = [r.p_60_start for r in starter_recs]
    played_60s = [r.played_60_plus for r in starter_recs]
    cal_p_60 = compute_calibration_bins(p_60_starts, played_60s)

    return BacktestResults(
        total_evaluations=len(records),
        overall_mae=round(overall_mae, 3),
        overall_rmse=round(overall_rmse, 3),
        mae_by_position=mae_by_pos,
        rmse_by_position=rmse_by_pos,
        ppg_baseline_mae=round(ppg_mae, 3),
        prev_gw_baseline_mae=round(prev_gw_mae, 3),
        captain_hit_rate=round(captain_hit_rate, 3),
        bootstrap_mae_ci=boot_mae_ci,
        bootstrap_rmse_ci=boot_rmse_ci,
        ppg_mae_ci=boot_ppg_ci,
        prev_gw_mae_ci=boot_prev_ci,
        by_position=by_position,
        calibration_p_start=cal_p_start,
        calibration_p_60_start=cal_p_60,
    )
