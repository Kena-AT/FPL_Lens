"""
Python Reference Implementation of the FPL Lens Device Optimiser (Spec §5 & §6).
Used as the test oracle for the pure Dart optimiser.
"""

from __future__ import annotations

import itertools
from dataclasses import dataclass

MIN_DEF, MIN_MID, MIN_FWD = 3, 2, 1
MAX_DEF, MAX_MID, MAX_FWD = 5, 5, 3

VALID_FORMATIONS = {
    (1, 3, 5, 2),
    (1, 3, 4, 3),
    (1, 4, 4, 2),
    (1, 4, 3, 3),
    (1, 4, 5, 1),
    (1, 5, 3, 2),
    (1, 5, 2, 3),
    (1, 5, 4, 1),
}


@dataclass(frozen=True)
class PlayerInput:
    fpl_id: int
    web_name: str
    position: str  # 'GK', 'DEF', 'MID', 'FWD'
    club_id: int
    price_tenths: int
    selling_price_tenths: int
    xp: float
    p_start: float
    p_sub: float = 0.0
    xp_start: float | None = None
    xp_sub: float | None = None

    @property
    def p_app(self) -> float:
        return min(1.0, max(0.0, self.p_start + self.p_sub))

    @property
    def conditional_xp_start(self) -> float:
        if self.xp_start is not None:
            return self.xp_start
        if self.p_start > 0.001:
            return self.xp / self.p_start
        return self.xp

    @property
    def conditional_xp_sub(self) -> float:
        if self.xp_sub is not None:
            return self.xp_sub
        # Substitute appearance typically yields 1-2 points
        if self.p_sub > 0.001:
            return min(self.xp, 1.8)
        return min(self.xp, 1.5)


@dataclass(frozen=True)
class LineupResult:
    starting_xi: list[PlayerInput]
    captain: PlayerInput
    vice_captain: PlayerInput
    bench: list[PlayerInput]  # [0] is backup GK, [1..3] are outfield subs in priority order
    total_expected_points: float
    captaincy_score: float
    bench_order_score: float
    is_quick_mode_fallback: bool = False
    formation: tuple[int, int, int, int] = (1, 4, 4, 2)


def formation_counts(players: list[PlayerInput]) -> dict[str, int]:
    c = {"GK": 0, "DEF": 0, "MID": 0, "FWD": 0}
    for p in players:
        c[p.position] = c.get(p.position, 0) + 1
    return c


def is_valid_xi(players: list[PlayerInput]) -> bool:
    if len(players) != 11:
        return False
    c = formation_counts(players)
    return (
        c["GK"] == 1
        and MIN_DEF <= c["DEF"] <= MAX_DEF
        and MIN_MID <= c["MID"] <= MAX_MID
        and MIN_FWD <= c["FWD"] <= MAX_FWD
    )


def enumerate_valid_xis(squad: list[PlayerInput]) -> list[list[PlayerInput]]:
    """
    Enumerate all 11-player subsets of the 15-player squad that satisfy formation rules.
    Combinations C(15, 11) = 1,365, of which valid formations are kept.
    """
    if len(squad) != 15:
        raise ValueError(f"Squad must contain exactly 15 players, got {len(squad)}")

    valid_xis: list[list[PlayerInput]] = []
    for combo in itertools.combinations(squad, 11):
        if is_valid_xi(list(combo)):
            valid_xis.append(list(combo))
    return valid_xis


def evaluate_captain_pair(xi: list[PlayerInput]) -> tuple[PlayerInput, PlayerInput, float]:
    """
    Spec §5.1 (v1.4 method): Evaluate all 110 ordered (captain, vice-captain) pairs inside XI.
    Pair(c, v) = sum_{i in XI} xP_i + xP_c + (1 - q_c) * xP_v
    where q_c = P(app_c).
    """
    xi_base_xp = sum(p.xp for p in xi)
    best_c: PlayerInput | None = None
    best_v: PlayerInput | None = None
    best_score = -float("inf")

    for c in xi:
        qc = c.p_app
        for v in xi:
            if c.fpl_id == v.fpl_id:
                continue
            pair_score = xi_base_xp + c.xp + (1.0 - qc) * v.xp
            if pair_score > best_score:
                best_score = pair_score
                best_c = c
                best_v = v

    assert best_c is not None and best_v is not None
    return best_c, best_v, best_score


def apply_fpl_auto_subs(
    starting_xi: list[PlayerInput],
    bench: list[PlayerInput],
    absent_ids: set[int],
) -> list[PlayerInput]:
    """
    Spec §5.2 Auto-subs logic:
    bench[0] is backup GK; bench[1:] are outfield substitutes in bench order.
    """
    xi = [p for p in starting_xi if p.fpl_id not in absent_ids]
    absent_starters = [p for p in starting_xi if p.fpl_id in absent_ids]

    # Goalkeeper substitution
    starter_gk_absent = any(p.position == "GK" for p in absent_starters)
    if starter_gk_absent and len(bench) > 0 and bench[0].fpl_id not in absent_ids:
        xi.append(bench[0])

    # Outfield substitutes in order
    outfield_missing = sum(1 for p in absent_starters if p.position != "GK")
    for sub in bench[1:]:
        if outfield_missing == 0:
            break
        if sub.fpl_id in absent_ids or sub.position == "GK":
            continue
        trial = xi + [sub]
        c = formation_counts(trial)
        slots_left = 11 - len(trial)
        below_min = (
            max(0, MIN_DEF - c["DEF"]) + max(0, MIN_MID - c["MID"]) + max(0, MIN_FWD - c["FWD"])
        )
        within_max = c["DEF"] <= MAX_DEF and c["MID"] <= MAX_MID and c["FWD"] <= MAX_FWD
        if within_max and below_min <= slots_left:
            xi = trial
            outfield_missing -= 1

    return xi


def evaluate_bench_orders(
    starting_xi: list[PlayerInput],
    bench_gk: PlayerInput,
    bench_outfield: list[PlayerInput],
    use_substitute_conditional_points: bool = True,
) -> tuple[list[PlayerInput], float]:
    """
    Spec §5.3: Exact bench-order evaluation over 2^11 = 2,048 starter absence patterns.
    Evaluates all 3! = 6 permutations of the 3 outfield bench players.
    Uses starter-conditional points for starters and substitute-conditional points
    for bench players who sub in (Spec §14 ledger requirement).
    """
    if len(bench_outfield) != 3:
        raise ValueError(f"Expected 3 outfield bench players, got {len(bench_outfield)}")

    starters = starting_xi
    n_starters = len(starters)
    starter_p_starts = [max(0.001, min(0.999, p.p_start)) for p in starters]

    # Precompute absence pattern probabilities
    # Filter states with prob >= 1e-8 for speed (covers >99.9999% probability mass)
    active_states: list[tuple[float, set[int]]] = []
    for state_idx in range(2048):
        prob = 1.0
        absent_ids: set[int] = set()
        for i in range(n_starters):
            if (state_idx >> i) & 1:
                prob *= 1.0 - starter_p_starts[i]
                absent_ids.add(starters[i].fpl_id)
            else:
                prob *= starter_p_starts[i]
        if prob > 1e-8:
            active_states.append((prob, absent_ids))

    starter_ids = {p.fpl_id for p in starters}
    best_order: list[PlayerInput] | None = None
    best_realised_score = -float("inf")

    # Evaluate 6 permutations
    for perm in itertools.permutations(bench_outfield):
        full_bench = [bench_gk] + list(perm)
        expected_points = 0.0

        for prob, absent_ids in active_states:
            final_xi = apply_fpl_auto_subs(starters, full_bench, absent_ids)

            # Sum realized points
            state_pts = 0.0
            for p in final_xi:
                if p.fpl_id in starter_ids:
                    state_pts += p.conditional_xp_start
                else:
                    if use_substitute_conditional_points:
                        state_pts += p.conditional_xp_sub
                    else:
                        state_pts += p.xp

            expected_points += prob * state_pts

        if expected_points > best_realised_score:
            best_realised_score = expected_points
            best_order = full_bench

    assert best_order is not None
    return best_order, best_realised_score


def optimize_lineup(
    squad: list[PlayerInput],
    quick_mode_threshold_xis: int = 1,
    force_fallback: bool = False,
) -> LineupResult:
    """
    Joint Starting XI, Captain, Vice-Captain, and Bench Order Optimiser (Spec §5.1, §5.2, §5.3).
    """
    if len(squad) != 15:
        raise ValueError("Squad must contain exactly 15 players")

    # Validate projections
    for p in squad:
        if p.xp < 0.0 and p.position != "GK":
            raise ValueError(f"Outfield player {p.web_name} has negative xP: {p.xp}")

    valid_xis = enumerate_valid_xis(squad)
    if not valid_xis:
        raise ValueError("No valid formation could be formed from the squad")

    # Evaluate captain pair for all valid XIs
    candidate_xis: list[tuple[list[PlayerInput], PlayerInput, PlayerInput, float]] = []
    for xi in valid_xis:
        c, v, pair_score = evaluate_captain_pair(xi)
        candidate_xis.append((xi, c, v, pair_score))

    # Sort descending by Pair score
    candidate_xis.sort(key=lambda item: item[3], reverse=True)

    # Spec §5.1 v1.4 method:
    # 1. Enumerate all valid XIs
    # 2. For each XI, evaluate all 110 ordered (c, v) pairs
    # 3. Choose best XI (maximum of XI score + captaincy pair score)
    # 4. Bench order (§5.3) is evaluated for the chosen XI.
    # Fallback mode: evaluate top 20 candidates.
    if force_fallback:
        top_candidates = candidate_xis[:20]
        is_fallback = True
    elif quick_mode_threshold_xis > 1:
        top_candidates = candidate_xis[:quick_mode_threshold_xis]
        is_fallback = True
    else:
        top_candidates = candidate_xis[:1]
        is_fallback = False

    best_result: LineupResult | None = None
    best_overall_score = -float("inf")

    for xi, c, v, _pair_score in top_candidates:
        xi_ids = {p.fpl_id for p in xi}
        bench_players = [p for p in squad if p.fpl_id not in xi_ids]

        bench_gks = [p for p in bench_players if p.position == "GK"]
        bench_outfields = [p for p in bench_players if p.position != "GK"]

        assert len(bench_gks) == 1, "Expected exactly 1 backup goalkeeper"
        assert len(bench_outfields) == 3, "Expected exactly 3 outfield bench players"

        bench_order, bench_score = evaluate_bench_orders(
            starting_xi=xi,
            bench_gk=bench_gks[0],
            bench_outfield=bench_outfields,
            use_substitute_conditional_points=True,
        )

        # Captain doubling bonus = xP_c + (1 - q_c) * xP_v
        qc = c.p_app
        captaincy_bonus = c.xp + (1.0 - qc) * v.xp
        total_score = bench_score + captaincy_bonus

        if total_score > best_overall_score:
            best_overall_score = total_score
            counts = formation_counts(xi)
            formation_tuple = (counts["GK"], counts["DEF"], counts["MID"], counts["FWD"])
            best_result = LineupResult(
                starting_xi=xi,
                captain=c,
                vice_captain=v,
                bench=bench_order,
                formation=formation_tuple,
                total_expected_points=total_score,
                captaincy_score=captaincy_bonus,
                bench_order_score=bench_score,
                is_quick_mode_fallback=is_fallback,
            )

    assert best_result is not None
    return best_result
