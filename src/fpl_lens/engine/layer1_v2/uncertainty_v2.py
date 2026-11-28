"""
Split-conformal prediction intervals (§5.9) and deterministic confidence labels (§7).
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field


def xp_bucket(xp: float) -> str:
    if xp < 2.0:
        return "low"
    if xp < 4.5:
        return "mid"
    return "high"


def _quantile(sorted_vals: list[float], q: float) -> float:
    if not sorted_vals:
        return 0.0
    idx = q * (len(sorted_vals) - 1)
    lo = int(math.floor(idx))
    hi = int(math.ceil(idx))
    if lo == hi:
        return sorted_vals[lo]
    frac = idx - lo
    return sorted_vals[lo] * (1.0 - frac) + sorted_vals[hi] * frac


@dataclass
class SplitConformalCalibrator:
    """
    Split-conformal residual quantiles (actual - xp) grouped by (position, xp_bucket).
    Produces 50% and 80% prediction intervals (§5.9).
    """

    group_quantiles_50: dict[tuple[str, str], tuple[float, float]] = field(default_factory=dict)
    group_quantiles_80: dict[tuple[str, str], tuple[float, float]] = field(default_factory=dict)
    global_50: tuple[float, float] = (-1.5, 2.0)
    global_80: tuple[float, float] = (-2.5, 4.5)

    @classmethod
    def fit(cls, records: list[tuple[str, float, float]]) -> SplitConformalCalibrator:
        """records: list of (position, predicted_xp, actual_points)."""
        if not records:
            return cls()
        all_res = sorted(actual - pred for _, pred, actual in records)
        g50 = (_quantile(all_res, 0.25), _quantile(all_res, 0.75))
        g80 = (_quantile(all_res, 0.10), _quantile(all_res, 0.90))

        buckets: dict[tuple[str, str], list[float]] = {}
        for pos, pred, actual in records:
            key = (pos.upper(), xp_bucket(pred))
            buckets.setdefault(key, []).append(actual - pred)

        q50: dict[tuple[str, str], tuple[float, float]] = {}
        q80: dict[tuple[str, str], tuple[float, float]] = {}
        for key, res in buckets.items():
            if len(res) >= 20:
                s = sorted(res)
                q50[key] = (_quantile(s, 0.25), _quantile(s, 0.75))
                q80[key] = (_quantile(s, 0.10), _quantile(s, 0.90))

        return cls(
            group_quantiles_50=q50,
            group_quantiles_80=q80,
            global_50=g50,
            global_80=g80,
        )

    def predict_intervals(
        self,
        position: str,
        xp: float,
    ) -> tuple[tuple[float, float], tuple[float, float]]:
        key = (position.upper(), xp_bucket(xp))
        lo50, hi50 = self.group_quantiles_50.get(key, self.global_50)
        lo80, hi80 = self.group_quantiles_80.get(key, self.global_80)
        return (xp + lo50, xp + hi50), (xp + lo80, xp + hi80)


def compute_confidence(
    *,
    is_stale: bool,
    sample_matches: int,
    interval80: tuple[float, float],
    is_availability_calibrated: bool,
    low_team_sample: bool,
    has_verify_rule: bool = False,
) -> tuple[str, tuple[str, ...]]:
    """
    Deterministic confidence classification per Engine Design §7.1 & §7.2:
      HIGH: 0 weakened conditions
      MEDIUM: 1 weakened condition
      LOW: >= 2 weakened conditions or stale/missing data
    """
    reasons: list[str] = []
    if is_stale:
        reasons.append("snapshot_stale")
    if sample_matches < 5:
        reasons.append("small_player_sample")
    if (interval80[1] - interval80[0]) > 10.0:
        reasons.append("wide_prediction_interval")
    if not is_availability_calibrated:
        reasons.append("uncalibrated_availability")
    if low_team_sample:
        reasons.append("small_team_sample")
    if has_verify_rule:
        reasons.append("verify_rule_dependency")

    if is_stale or len(reasons) >= 2:
        return "LOW", tuple(reasons)
    if len(reasons) == 1:
        return "MEDIUM", tuple(reasons)
    return "HIGH", ()
