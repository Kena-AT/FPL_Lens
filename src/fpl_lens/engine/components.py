"""
Component calculations of expected points per Technical Specification §4.
"""

import math

from fpl_lens.engine.types import PlayerMatchHistory, PlayingTimeScenarios, ProjectionComponents


class ProjectionValidationError(ValueError):
    """Raised when an expected points component or final value violates configured bounds."""

    pass


# Weights per Technical Spec §4.2 & §4.3 [VERIFIED-2ND]
GOAL_WEIGHTS = {"GK": 10.0, "DEF": 6.0, "MID": 5.0, "FWD": 4.0}
CLEAN_SHEET_WEIGHTS = {"GK": 4.0, "DEF": 4.0, "MID": 1.0, "FWD": 0.0}

# Empirical baseline priors [PLACEHOLDER per Spec §4.5, §4.6, §4.7]
DC_PRIORS_BY_BAND = {
    "GK": {"under_60": 0.0, "60_plus": 0.0},
    "DEF": {"under_60": 0.03, "60_plus": 0.18},
    "MID": {"under_60": 0.015, "60_plus": 0.08},
    "FWD": {"under_60": 0.005, "60_plus": 0.02},
}

BONUS_RATES = {"GK": 0.25, "DEF": 0.32, "MID": 0.38, "FWD": 0.45}
CARD_RATES = {
    "GK": {"yellow": 0.03, "red": 0.001},
    "DEF": {"yellow": 0.14, "red": 0.005},
    "MID": {"yellow": 0.12, "red": 0.004},
    "FWD": {"yellow": 0.08, "red": 0.003},
}

# Configured output bounds [PLACEHOLDER per Spec §4 and Implementation Plan]
PROJECTION_BOUNDS = {
    "exp_appearance": (0.0, 2.0),
    "exp_goals": (0.0, 10.0),
    "exp_assists": (0.0, 8.0),
    "exp_clean_sheet": (0.0, 4.0),
    "exp_goals_conceded": (-10.0, 0.0),
    "exp_dc": (0.0, 2.0),
    "exp_bonus": (0.0, 3.0),
    "exp_card_penalty": (0.0, 3.0),
    "expected_points_outfield": (0.0, 25.0),
    "expected_points_gk": (-4.0, 20.0),
}


def calculate_appearance_points(pt: PlayingTimeScenarios) -> float:
    """
    Spec §4.1:
    E[App] = 0 * P(S_A) + 1 * (P(S_B) + P(S_D)) + 2 * (P(S_C) + P(S_E))
    """
    return 1.0 * (pt.p_sb + pt.p_sd) + 2.0 * (pt.p_sc + pt.p_se)


def calculate_goals_and_assists(
    xg_90: float,
    xa_90: float,
    expected_minutes: float,
    lambda_scored: float,
    mu: float,
    position: str,
) -> tuple[float, float]:
    """
    Spec §4.2:
    E[Goals] = xG_90 * (E[Min] / 90) * (lambda_scored / mu) * W_goal[pos]
    E[Assists] = xA_90 * (E[Min] / 90) * (lambda_scored / mu) * 3
    """
    if mu <= 0:
        mu = 1.35
    pos = position.upper()
    w_goal = GOAL_WEIGHTS.get(pos, 4.0)

    scaling = (expected_minutes / 90.0) * (lambda_scored / mu)
    exp_goals = xg_90 * scaling * w_goal
    exp_assists = xa_90 * scaling * 3.0

    return max(0.0, exp_goals), max(0.0, exp_assists)


def calculate_clean_sheet_points(
    pt: PlayingTimeScenarios,
    lambda_conceded: float,
    position: str,
) -> float:
    """
    Spec §4.3:
    E[CS] = W_cs[pos] * (P(S_C) * e^(-lambda_conc * M_sc / 90) + P(S_E) * e^(-lambda_conc * M_se / 90))
    """
    pos = position.upper()
    w_cs = CLEAN_SHEET_WEIGHTS.get(pos, 0.0)
    if w_cs <= 0.0:
        return 0.0

    cs_prob = pt.p_sc * math.exp(-lambda_conceded * (pt.m_sc / 90.0)) + pt.p_se * math.exp(
        -lambda_conceded * (pt.m_se / 90.0)
    )
    return w_cs * cs_prob


def calculate_goals_conceded_penalty(
    pt: PlayingTimeScenarios,
    lambda_conceded: float,
    position: str,
    tail_tolerance: float = 1e-6,
) -> float:
    """
    Spec §4.4: Exact Poisson sum for GK and DEF only:
    E[GC] = - sum_{s in B,C,D,E} P(S_s) * sum_{k=0}^K floor(k/2) * (lambda_s^k * e^(-lambda_s) / k!)
    Truncated at K where remaining tail mass is < 1e-6.
    """
    pos = position.upper()
    if pos not in ("GK", "DEF"):
        return 0.0

    scenarios = [
        (pt.p_sb, pt.m_sb),
        (pt.p_sc, pt.m_sc),
        (pt.p_sd, pt.m_sd),
        (pt.p_se, pt.m_se),
    ]

    total_penalty = 0.0

    for p_s, m_s in scenarios:
        if p_s <= 0.0 or m_s <= 0.0:
            continue

        lam_s = lambda_conceded * (m_s / 90.0)
        exp_neg_lam = math.exp(-lam_s)

        scenario_penalty = 0.0
        prob_sum = 0.0
        term_prob = exp_neg_lam  # for k=0: lam_s^0 / 0! * e^-lam_s = e^-lam_s
        k = 0

        while True:
            prob_sum += term_prob
            penalty_k = k // 2
            scenario_penalty += penalty_k * term_prob

            k += 1
            term_prob = term_prob * lam_s / k

            # Stop when tail mass is below tolerance
            if 1.0 - prob_sum < tail_tolerance or k > 30:
                break

        total_penalty += p_s * scenario_penalty

    # Return as non-positive value
    return -total_penalty


def calculate_defensive_contributions(
    pt: PlayingTimeScenarios,
    position: str,
    history: list[PlayerMatchHistory] | None = None,
    shrinkage_weight: float = 3.0,
) -> float:
    """
    Spec §4.5: Empirical baseline method:
    P(DC) = Rate_{DC, pos, mins band} (historical, shrunk to pos prior)
    E[DC] = 2 * P(DC) * P(app)
    where P(app) = 1 - P(S_A)
    """
    pos = position.upper()
    p_app = 1.0 - pt.p_sa
    if p_app <= 1e-6:
        return 0.0

    priors = DC_PRIORS_BY_BAND.get(pos, {"under_60": 0.0, "60_plus": 0.0})

    if history:
        apps = [h for h in history if h.minutes > 0]
        apps_60 = [h for h in apps if h.minutes >= 60]
        apps_under = [h for h in apps if h.minutes < 60]

        # 60+ band empirical rate shrunk to prior
        k_60 = len(apps_60)
        emp_60 = (
            sum(1 for h in apps_60 if h.defensive_contributions > 0) / k_60
            if k_60 > 0
            else priors["60_plus"]
        )
        w_60 = k_60 / (k_60 + shrinkage_weight)
        rate_60 = w_60 * emp_60 + (1.0 - w_60) * priors["60_plus"]

        # under 60 band empirical rate shrunk to prior
        k_under = len(apps_under)
        emp_under = (
            sum(1 for h in apps_under if h.defensive_contributions > 0) / k_under
            if k_under > 0
            else priors["under_60"]
        )
        w_under = k_under / (k_under + shrinkage_weight)
        rate_under = w_under * emp_under + (1.0 - w_under) * priors["under_60"]
    else:
        rate_60 = priors["60_plus"]
        rate_under = priors["under_60"]

    # Weight by probability of playing in each band given appearance
    p_60_given_app = (pt.p_sc + pt.p_se) / p_app
    p_under_given_app = (pt.p_sb + pt.p_sd) / p_app

    p_dc = p_60_given_app * rate_60 + p_under_given_app * rate_under
    return 2.0 * p_dc * p_app


def calculate_bonus(
    pt: PlayingTimeScenarios,
    position: str,
) -> float:
    """
    Spec §4.6:
    E[Bonus] = Rate_bonus,pos * P(app)
    """
    pos = position.upper()
    p_app = 1.0 - pt.p_sa
    rate_bonus = BONUS_RATES.get(pos, 0.25)
    return rate_bonus * p_app


def calculate_card_penalty(
    pt: PlayingTimeScenarios,
    position: str,
) -> float:
    """
    Spec §4.7:
    E[Cards] = (P_yel * 1 + P_red * 3) * P(app)
    Returns positive magnitude to be subtracted.
    """
    pos = position.upper()
    p_app = 1.0 - pt.p_sa
    rates = CARD_RATES.get(pos, {"yellow": 0.10, "red": 0.003})
    return (rates["yellow"] * 1.0 + rates["red"] * 3.0) * p_app


def validate_projection_output(
    components: ProjectionComponents,
    position: str,
    bounds: dict[str, tuple[float, float]] = PROJECTION_BOUNDS,
) -> None:
    """
    Validates that every component and final expected points are finite,
    outfield expected points are strictly non-negative (rejecting negative values),
    and all components lie within configured bounds per Spec §4 & Implementation Plan.
    """
    pos = position.upper()

    # 1. Finite check
    for field_name in (
        "exp_appearance",
        "exp_goals",
        "exp_assists",
        "exp_clean_sheet",
        "exp_goals_conceded",
        "exp_dc",
        "exp_bonus",
        "exp_card_penalty",
        "expected_points",
    ):
        val = getattr(components, field_name)
        if not math.isfinite(val):
            raise ProjectionValidationError(f"Projection value {field_name}={val} is not finite")

    # 2. Strict non-negative check for outfield players (rejection, not clamping)
    if pos in ("DEF", "MID", "FWD") and components.expected_points < 0.0:
        raise ProjectionValidationError(
            f"Validation failed: Outfield player ({pos}) has negative expected points: {components.expected_points}"
        )

    # 3. Configured bounds checks
    for comp_name, (low, high) in bounds.items():
        if comp_name == "expected_points_outfield" and pos in ("DEF", "MID", "FWD"):
            if not (low <= components.expected_points <= high):
                raise ProjectionValidationError(
                    f"Outfield expected points {components.expected_points} outside bounds [{low}, {high}]"
                )
        elif comp_name == "expected_points_gk" and pos == "GK":
            if not (low <= components.expected_points <= high):
                raise ProjectionValidationError(
                    f"GK expected points {components.expected_points} outside bounds [{low}, {high}]"
                )
        elif hasattr(components, comp_name):
            val = getattr(components, comp_name)
            if not (low <= val <= high):
                raise ProjectionValidationError(
                    f"Component {comp_name}={val} outside configured bounds [{low}, {high}]"
                )


def compute_projection_components(
    pt: PlayingTimeScenarios,
    xg_90: float,
    xa_90: float,
    lambda_scored: float,
    lambda_conceded: float,
    mu: float,
    position: str,
    history: list[PlayerMatchHistory] | None = None,
    enforce_validation: bool = True,
) -> ProjectionComponents:
    """
    Assembles all components and computes final expected points xP per Spec §4:
    xP = E[App] + E[Goals] + E[Assists] + E[CS] + E[GC] + E[DC] + E[Bonus] - E[Cards]
    Rejects invalid/negative outfield values without clamping.
    """
    exp_app = calculate_appearance_points(pt)
    exp_goals, exp_assists = calculate_goals_and_assists(
        xg_90=xg_90,
        xa_90=xa_90,
        expected_minutes=pt.expected_minutes,
        lambda_scored=lambda_scored,
        mu=mu,
        position=position,
    )
    exp_cs = calculate_clean_sheet_points(pt, lambda_conceded=lambda_conceded, position=position)
    exp_gc = calculate_goals_conceded_penalty(
        pt, lambda_conceded=lambda_conceded, position=position
    )
    exp_dc = calculate_defensive_contributions(pt, position=position, history=history)
    exp_bonus = calculate_bonus(pt, position=position)
    exp_cards = calculate_card_penalty(pt, position=position)

    raw_xp = exp_app + exp_goals + exp_assists + exp_cs + exp_gc + exp_dc + exp_bonus - exp_cards

    components = ProjectionComponents(
        exp_appearance=exp_app,
        exp_goals=exp_goals,
        exp_assists=exp_assists,
        exp_clean_sheet=exp_cs,
        exp_goals_conceded=exp_gc,
        exp_dc=exp_dc,
        exp_bonus=exp_bonus,
        exp_card_penalty=exp_cards,
        expected_points=raw_xp,
    )

    if enforce_validation:
        validate_projection_output(components, position=position)

    return components
