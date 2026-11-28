"""
Empirical availability calibration alpha(s, c, a) per Engine Design §5.2.
Falls back to uncalibrated FPL values until archive cells meet min_count.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime

from fpl_lens.engine.availability import calculate_availability as raw_availability


def news_age_band(news_added_at: datetime | None, as_of: datetime | None) -> str:
    """Buckets hours since news_added into discrete bands."""
    if news_added_at is None or as_of is None:
        return "none"
    hours = max(0.0, (as_of - news_added_at).total_seconds() / 3600.0)
    if hours <= 24.0:
        return "0_24h"
    if hours <= 72.0:
        return "24_72h"
    return "72h_plus"


def chance_bucket(chance: int | float | None) -> str:
    if chance is None:
        return "none"
    val = int(round(float(chance)))
    for b in (0, 25, 50, 75, 100):
        if abs(val - b) <= 12:
            return str(b)
    return str(max(0, min(100, val)))


@dataclass
class AvailabilityCalibrator:
    """Beta-smoothed empirical rate P(plays >= 1 min | status, chance_label, news_age_band)."""

    min_cell_count: int = 20
    prior_strength: float = 4.0
    cell_counts: dict[tuple[str, str, str], tuple[int, int]] = field(default_factory=dict)

    @classmethod
    def fit(
        cls,
        observations: list[tuple[str, int | None, str, bool]],
        *,
        min_cell_count: int = 20,
        prior_strength: float = 4.0,
    ) -> AvailabilityCalibrator:
        counts: dict[tuple[str, str, str], list[int]] = {}
        for status, chance, age_band, played in observations:
            key = ((status or "").strip().lower(), chance_bucket(chance), age_band)
            if key not in counts:
                counts[key] = [0, 0]
            counts[key][1] += 1
            if played:
                counts[key][0] += 1
        frozen = {k: (v[0], v[1]) for k, v in counts.items()}
        return cls(
            min_cell_count=min_cell_count,
            prior_strength=prior_strength,
            cell_counts=frozen,
        )

    def predict(
        self,
        status: str,
        chance_of_playing: int | float | None,
        news_added_at: datetime | None = None,
        as_of: datetime | None = None,
    ) -> tuple[float, bool]:
        """Returns (alpha, is_calibrated)."""
        clean_status = (status or "").strip().lower()
        prior = raw_availability(clean_status, chance_of_playing)
        age = news_age_band(news_added_at, as_of)
        key = (clean_status, chance_bucket(chance_of_playing), age)
        cell = self.cell_counts.get(key)
        if cell is None or cell[1] < self.min_cell_count:
            return prior, False

        played_count, total_count = cell
        alpha = (played_count + self.prior_strength * prior) / (total_count + self.prior_strength)
        return max(0.0, min(1.0, alpha)), True
