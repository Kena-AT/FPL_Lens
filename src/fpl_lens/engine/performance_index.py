"""
Performance Index (POI) calculation per Technical Specification §13A (v1.6).
A derived 0-100 index per starting player for ordering starters and tactical display.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class StarterInput:
    player_id: int
    xp: float | None
    p_start: float | None
    form: float | None
    ppg: float | None


@dataclass(frozen=True)
class PerformanceIndexResult:
    player_id: int
    poi: int
    is_partial: bool


def calculate_performance_index(
    starters: list[StarterInput],
    w_xp: float = 0.6,
    w_start: float = 0.2,
    w_form: float = 0.1,
    w_ppg: float = 0.1,
) -> list[PerformanceIndexResult] | None:
    """
    Computes Performance Index (POI) for the starting XI according to Spec §13A.

    Rules:
    - Must have exactly 11 starters.
    - If xP or P_start is missing for any starter, index cannot be computed (returns None).
    - If form or ppg fails to parse (is None) for a player, that term is excluded for that player
      and the result is labelled 'partial'.
    - Normalisation within the starting XI: n_k = (x_k - min_k) / (max_k - min_k).
      If max_k == min_k, n_k = 0.5.
    - POI_p = round(100 * sum(w_k * n_k) / sum(w_k of included terms)), clamped to [0, 100].
    """
    if len(starters) != 11:
        raise ValueError(f"Performance Index requires exactly 11 starters, got {len(starters)}")

    # Check mandatory model outputs
    for s in starters:
        if s.xp is None or s.p_start is None:
            return None

    # Extract terms for normalisation across 11 starters
    def get_min_max(values: list[float | None]) -> tuple[float, float]:
        present = [v for v in values if v is not None]
        if not present:
            return (0.0, 0.0)
        return (min(present), max(present))

    min_xp, max_xp = get_min_max([s.xp for s in starters])
    min_st, max_st = get_min_max([s.p_start for s in starters])
    min_fm, max_fm = get_min_max([s.form for s in starters])
    min_pg, max_pg = get_min_max([s.ppg for s in starters])

    def normalize(val: float | None, mn: float, mx: float) -> float | None:
        if val is None:
            return None
        if abs(mx - mn) < 1e-9:
            return 0.5
        return (val - mn) / (mx - mn)

    results: list[PerformanceIndexResult] = []

    for s in starters:
        is_partial = (s.form is None) or (s.ppg is None)

        n_xp = normalize(s.xp, min_xp, max_xp)
        n_st = normalize(s.p_start, min_st, max_st)
        n_fm = normalize(s.form, min_fm, max_fm)
        n_pg = normalize(s.ppg, min_pg, max_pg)

        weighted_sum = 0.0
        weights_sum = 0.0

        if n_xp is not None:
            weighted_sum += w_xp * n_xp
            weights_sum += w_xp
        if n_st is not None:
            weighted_sum += w_start * n_st
            weights_sum += w_start
        if n_fm is not None:
            weighted_sum += w_form * n_fm
            weights_sum += w_form
        if n_pg is not None:
            weighted_sum += w_ppg * n_pg
            weights_sum += w_ppg

        if weights_sum <= 0:
            poi = 50
        else:
            raw_poi = 100.0 * (weighted_sum / weights_sum)
            poi = max(0, min(100, round(raw_poi)))

        results.append(
            PerformanceIndexResult(
                player_id=s.player_id,
                poi=poi,
                is_partial=is_partial,
            )
        )

    return results
