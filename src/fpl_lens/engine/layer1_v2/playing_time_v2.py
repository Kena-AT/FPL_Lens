"""
Layer 1 v2 Playing-Time model (§5.2) and PAVA Isotonic Regression calibrator (§5.9).
Replaces fixed 5-GW window with exponential time decay, unavailable-spell exclusion,
and hierarchical shrinkage toward role priors.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

from fpl_lens.engine.playing_time import DEFAULT_PRIOR, ROLE_PRIORS
from fpl_lens.engine.types import PlayerMatchHistory, PlayingTimeScenarios


@dataclass(frozen=True)
class IsotonicCalibrator:
    """Monotonic Pool-Adjacent-Violators (PAVA) probability calibrator."""

    x_thresholds: tuple[float, ...]
    y_values: tuple[float, ...]

    @classmethod
    def fit(cls, probs: list[float], outcomes: list[bool]) -> IsotonicCalibrator:
        if not probs or len(probs) != len(outcomes):
            return cls(x_thresholds=(0.0, 1.0), y_values=(0.0, 1.0))

        paired = sorted(zip(probs, outcomes, strict=True), key=lambda t: t[0])
        # PAVA blocks: [sum_y, weight, min_x, max_x]
        blocks: list[list[float]] = []
        for x, y in paired:
            blocks.append([1.0 if y else 0.0, 1.0, float(x), float(x)])
            while len(blocks) >= 2:
                prev_mean = blocks[-2][0] / blocks[-2][1]
                curr_mean = blocks[-1][0] / blocks[-1][1]
                if prev_mean <= curr_mean:
                    break
                last = blocks.pop()
                blocks[-1][0] += last[0]
                blocks[-1][1] += last[1]
                blocks[-1][3] = last[3]

        xs = tuple((b[2] + b[3]) / 2.0 for b in blocks)
        ys = tuple(max(0.0, min(1.0, b[0] / b[1])) for b in blocks)
        return cls(x_thresholds=xs, y_values=ys)

    def predict(self, p: float) -> float:
        if not self.x_thresholds:
            return max(0.0, min(1.0, p))
        if p <= self.x_thresholds[0]:
            return self.y_values[0]
        if p >= self.x_thresholds[-1]:
            return self.y_values[-1]
        for i in range(len(self.x_thresholds) - 1):
            x0, x1 = self.x_thresholds[i], self.x_thresholds[i + 1]
            if x0 <= p <= x1:
                if abs(x1 - x0) < 1e-12:
                    return self.y_values[i]
                t = (p - x0) / (x1 - x0)
                return self.y_values[i] + t * (self.y_values[i + 1] - self.y_values[i])
        return max(0.0, min(1.0, p))


def filter_available_history(
    history: list[PlayerMatchHistory],
    min_unavailable_spell: int = 3,
) -> list[PlayerMatchHistory]:
    """
    Excludes contiguous runs of 0-minute gameweeks of length >= min_unavailable_spell
    so injury/suspension spells do not masquerade as rotation (§5.2).
    """
    if not history:
        return []
    ordered = sorted(history, key=lambda h: h.gameweek)
    keep: list[PlayerMatchHistory] = []
    zero_run: list[PlayerMatchHistory] = []

    for h in ordered:
        if h.minutes == 0:
            zero_run.append(h)
        else:
            if len(zero_run) < min_unavailable_spell:
                keep.extend(zero_run)
            zero_run = []
            keep.append(h)
    if len(zero_run) < min_unavailable_spell:
        keep.extend(zero_run)
    return keep


def calculate_playing_time_v2(
    *,
    availability: float,
    history: list[PlayerMatchHistory],
    target_gameweek: int,
    position: str = "MID",
    half_life_gws: float = 6.0,
    kappa: float = 3.0,
    min_unavailable_spell: int = 3,
    start_calibrator: IsotonicCalibrator | None = None,
    p60_calibrator: IsotonicCalibrator | None = None,
) -> PlayingTimeScenarios:
    """
    Computes 5-scenario playing time partition with exponential time decay,
    unavailable-spell exclusion, and optional isotonic post-calibration (§5.2, §5.9).
    Enforces I12: p_sa + p_sb + p_sc + p_sd + p_se == 1.0 and p_start + p_sub + p_sa == 1.0.
    """
    pos_prior = ROLE_PRIORS.get(position.upper(), DEFAULT_PRIOR)
    alpha = max(0.0, min(1.0, float(availability)))
    avail_hist = filter_available_history(history, min_unavailable_spell=min_unavailable_spell)

    if not avail_hist:
        rate_start = pos_prior["rate_start"]
        rate_sub = pos_prior["rate_sub"]
        p_60_start = pos_prior["p_60_start"]
        p_60_sub = pos_prior["p_60_sub"]
        m_se = pos_prior["m_se"]
        m_sd = pos_prior["m_sd"]
        m_sc = pos_prior["m_sc"]
        m_sb = pos_prior["m_sb"]
    else:
        weights = [
            0.5 ** (max(0, target_gameweek - h.gameweek) / max(0.5, half_life_gws))
            for h in avail_hist
        ]
        w_sum = sum(weights)
        start_w = sum(w for w, h in zip(weights, avail_hist, strict=True) if h.was_starter)
        rate_start = (start_w + kappa * pos_prior["rate_start"]) / (w_sum + kappa)

        non_starts = [(w, h) for w, h in zip(weights, avail_hist, strict=True) if not h.was_starter]
        ns_w_sum = sum(w for w, _ in non_starts)
        sub_w = sum(w for w, h in non_starts if h.minutes > 0)
        rate_sub = (sub_w + kappa * pos_prior["rate_sub"]) / (ns_w_sum + kappa)

        starts = [(w, h) for w, h in zip(weights, avail_hist, strict=True) if h.was_starter]
        s_w_sum = sum(w for w, _ in starts)
        s60_w = sum(w for w, h in starts if h.minutes >= 60)
        p_60_start = (s60_w + kappa * pos_prior["p_60_start"]) / (s_w_sum + kappa)

        sub_apps = [(w, h) for w, h in non_starts if h.minutes > 0]
        sa_w_sum = sum(w for w, _ in sub_apps)
        sa60_w = sum(w for w, h in sub_apps if h.minutes >= 60)
        p_60_sub = (sa60_w + kappa * pos_prior["p_60_sub"]) / (sa_w_sum + kappa)

        def _shrunk_mins(items: list[tuple[float, PlayerMatchHistory]], prior_m: float) -> float:
            wt = sum(w for w, _ in items)
            if wt <= 0:
                return prior_m
            num = sum(w * h.minutes for w, h in items) + kappa * prior_m
            return num / (wt + kappa)

        m_se = _shrunk_mins([(w, h) for w, h in starts if h.minutes >= 60], pos_prior["m_se"])
        m_sd = _shrunk_mins([(w, h) for w, h in starts if h.minutes < 60], pos_prior["m_sd"])
        m_sc = _shrunk_mins([(w, h) for w, h in non_starts if h.minutes >= 60], pos_prior["m_sc"])
        m_sb = _shrunk_mins([(w, h) for w, h in non_starts if 0 < h.minutes < 60], pos_prior["m_sb"])

    rate_start = max(0.0, min(1.0, rate_start))
    rate_sub = max(0.0, min(1.0, rate_sub))
    p_60_start = max(0.0, min(1.0, p_60_start))
    p_60_sub = max(0.0, min(1.0, p_60_sub))

    if p60_calibrator is not None:
        p_60_start = max(0.0, min(1.0, p60_calibrator.predict(p_60_start)))

    p_start = alpha * rate_start
    if start_calibrator is not None and alpha > 0.0:
        p_start = max(0.0, min(alpha, start_calibrator.predict(p_start)))

    p_sub = max(0.0, min(1.0 - p_start, alpha * (1.0 - rate_start) * rate_sub))
    p_sa = max(0.0, 1.0 - p_start - p_sub)

    p_se = p_start * p_60_start
    p_sd = p_start - p_se
    p_sc = p_sub * p_60_sub
    p_sb = p_sub - p_sc

    expected_minutes = p_sb * m_sb + p_sc * m_sc + p_sd * m_sd + p_se * m_se
    if not math.isfinite(expected_minutes):
        raise ValueError("Non-finite expected_minutes in calculate_playing_time_v2")

    return PlayingTimeScenarios(
        p_sa=p_sa,
        p_sb=p_sb,
        p_sc=p_sc,
        p_sd=p_sd,
        p_se=p_se,
        m_sb=m_sb,
        m_sc=m_sc,
        m_sd=m_sd,
        m_se=m_se,
        expected_minutes=expected_minutes,
        p_start=p_start,
        p_sub=p_sub,
        p_60_plus_given_start=p_60_start,
        p_60_plus_given_sub=p_60_sub,
        availability=alpha,
    )
