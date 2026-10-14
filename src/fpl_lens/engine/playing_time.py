"""
Playing-time model and 5-scenario partition per Technical Specification §3.2.
"""

from fpl_lens.engine.types import PlayerMatchHistory, PlayingTimeScenarios

# Role-level priors [PLACEHOLDER per Spec §3.2]
ROLE_PRIORS = {
    "GK": {
        "rate_start": 0.85,
        "rate_sub": 0.05,
        "p_60_start": 0.98,
        "p_60_sub": 0.02,
        "m_se": 90.0,
        "m_sd": 45.0,
        "m_sc": 65.0,
        "m_sb": 20.0,
    },
    "DEF": {
        "rate_start": 0.70,
        "rate_sub": 0.35,
        "p_60_start": 0.88,
        "p_60_sub": 0.05,
        "m_se": 90.0,
        "m_sd": 45.0,
        "m_sc": 65.0,
        "m_sb": 20.0,
    },
    "MID": {
        "rate_start": 0.65,
        "rate_sub": 0.45,
        "p_60_start": 0.75,
        "p_60_sub": 0.05,
        "m_se": 82.0,
        "m_sd": 45.0,
        "m_sc": 65.0,
        "m_sb": 22.0,
    },
    "FWD": {
        "rate_start": 0.60,
        "rate_sub": 0.50,
        "p_60_start": 0.70,
        "p_60_sub": 0.05,
        "m_se": 80.0,
        "m_sd": 45.0,
        "m_sc": 65.0,
        "m_sb": 24.0,
    },
}

DEFAULT_PRIOR = ROLE_PRIORS["MID"]


def calculate_playing_time(
    availability: float,
    history: list[PlayerMatchHistory],
    position: str = "MID",
    window_size: int = 5,
    shrinkage_weight: float = 2.0,
) -> PlayingTimeScenarios:
    """
    Computes 5-scenario partition per Spec §3.2:
      S_A: No appearance
      S_B: Substitute, under 60 min
      S_C: Substitute, 60+ min
      S_D: Starter, under 60 min
      S_E: Starter, 60+ min
    """
    pos_prior = ROLE_PRIORS.get(position.upper(), DEFAULT_PRIOR)
    alpha = max(0.0, min(1.0, float(availability)))

    # Take the most recent window_size matches
    recent = history[-window_size:] if history else []
    n = len(recent)

    if n == 0:
        rate_start = pos_prior["rate_start"]
        rate_sub = pos_prior["rate_sub"]
        p_60_given_start = pos_prior["p_60_start"]
        p_60_given_sub = pos_prior["p_60_sub"]
        m_se = pos_prior["m_se"]
        m_sd = pos_prior["m_sd"]
        m_sc = pos_prior["m_sc"]
        m_sb = pos_prior["m_sb"]
    else:
        # Starter rate over window
        starts = [h for h in recent if h.was_starter]
        k_start = len(starts)
        emp_rate_start = k_start / n
        # Shrinkage toward position prior
        w_start = n / (n + shrinkage_weight)
        rate_start = w_start * emp_rate_start + (1.0 - w_start) * pos_prior["rate_start"]

        # Sub rate over matches player did not start
        non_starts = [h for h in recent if not h.was_starter]
        k_non_starts = len(non_starts)
        if k_non_starts > 0:
            subs = [h for h in non_starts if h.minutes > 0]
            emp_rate_sub = len(subs) / k_non_starts
            w_sub = k_non_starts / (k_non_starts + shrinkage_weight)
            rate_sub = w_sub * emp_rate_sub + (1.0 - w_sub) * pos_prior["rate_sub"]
        else:
            rate_sub = pos_prior["rate_sub"]

        # P(60+ | start)
        if k_start > 0:
            starts_60_plus = [h for h in starts if h.minutes >= 60]
            emp_p60_start = len(starts_60_plus) / k_start
            w_p60_start = k_start / (k_start + shrinkage_weight)
            p_60_given_start = w_p60_start * emp_p60_start + (1.0 - w_p60_start) * pos_prior["p_60_start"]
        else:
            p_60_given_start = pos_prior["p_60_start"]

        # P(60+ | sub)
        sub_apps = [h for h in non_starts if h.minutes > 0]
        if sub_apps:
            subs_60_plus = [h for h in sub_apps if h.minutes >= 60]
            emp_p60_sub = len(subs_60_plus) / len(sub_apps)
            w_p60_sub = len(sub_apps) / (len(sub_apps) + shrinkage_weight)
            p_60_given_sub = w_p60_sub * emp_p60_sub + (1.0 - w_p60_sub) * pos_prior["p_60_sub"]
        else:
            p_60_given_sub = pos_prior["p_60_sub"]

        # Shrunk minutes per scenario
        m_se_vals = [h.minutes for h in starts if h.minutes >= 60]
        m_se = (
            (sum(m_se_vals) + shrinkage_weight * pos_prior["m_se"]) / (len(m_se_vals) + shrinkage_weight)
            if m_se_vals
            else pos_prior["m_se"]
        )

        m_sd_vals = [h.minutes for h in starts if h.minutes < 60]
        m_sd = (
            (sum(m_sd_vals) + shrinkage_weight * pos_prior["m_sd"]) / (len(m_sd_vals) + shrinkage_weight)
            if m_sd_vals
            else pos_prior["m_sd"]
        )

        m_sc_vals = [h.minutes for h in non_starts if h.minutes >= 60]
        m_sc = (
            (sum(m_sc_vals) + shrinkage_weight * pos_prior["m_sc"]) / (len(m_sc_vals) + shrinkage_weight)
            if m_sc_vals
            else pos_prior["m_sc"]
        )

        m_sb_vals = [h.minutes for h in non_starts if 0 < h.minutes < 60]
        m_sb = (
            (sum(m_sb_vals) + shrinkage_weight * pos_prior["m_sb"]) / (len(m_sb_vals) + shrinkage_weight)
            if m_sb_vals
            else pos_prior["m_sb"]
        )

    # Ensure probabilities are bounded in [0, 1]
    rate_start = max(0.0, min(1.0, rate_start))
    rate_sub = max(0.0, min(1.0, rate_sub))
    p_60_given_start = max(0.0, min(1.0, p_60_given_start))
    p_60_given_sub = max(0.0, min(1.0, p_60_given_sub))

    # Spec §3.2 formulas:
    # P(Start) = alpha * Rate_start
    p_start = alpha * rate_start
    # P(Sub) = alpha * (1 - Rate_start) * Rate_sub
    p_sub = alpha * (1.0 - rate_start) * rate_sub

    # Scenario probabilities:
    # S_E: Starter, 60+ min
    p_se = p_start * p_60_given_start
    # S_D: Starter, under 60 min
    p_sd = p_start - p_se
    # S_C: Sub, 60+ min
    p_sc = p_sub * p_60_given_sub
    # S_B: Sub, under 60 min
    p_sb = p_sub * (1.0 - p_60_given_sub)
    # S_A: No appearance (1 - P(Start) - P(Sub))
    p_sa = max(0.0, 1.0 - p_start - p_sub)

    # Expected minutes: E[Min] = sum_{s in B,C,D,E} P(S_s) * M_s
    expected_minutes = p_sb * m_sb + p_sc * m_sc + p_sd * m_sd + p_se * m_se

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
        p_60_plus_given_start=p_60_given_start,
        p_60_plus_given_sub=p_60_given_sub,
        availability=alpha,
    )
