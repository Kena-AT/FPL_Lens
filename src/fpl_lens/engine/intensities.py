"""
Team attacking and defensive intensities per Technical Specification §3.3.
"""

from fpl_lens.engine.types import TeamStrength


def compute_league_averages(
    teams: list[TeamStrength], total_goals: int = 0, matches_played: int = 0
) -> dict[str, float]:
    """
    Computes league-average goals per match mu and average strength components.
    mu = total_goals / (2 * matches_played), defaulting to 1.35 [PLACEHOLDER] if matches == 0.
    """
    if matches_played > 0 and total_goals >= 0:
        mu = float(total_goals) / (2.0 * float(matches_played))
    else:
        mu = 1.35  # Illustrative league average [PLACEHOLDER]

    if not teams:
        return {
            "mu": mu,
            "att_home_avg": 1000.0,
            "att_away_avg": 1000.0,
            "def_home_avg": 1000.0,
            "def_away_avg": 1000.0,
        }

    n = len(teams)
    att_home_avg = sum(t.strength_attack_home for t in teams) / n
    att_away_avg = sum(t.strength_attack_away for t in teams) / n
    def_home_avg = sum(t.strength_defence_home for t in teams) / n
    def_away_avg = sum(t.strength_defence_away for t in teams) / n

    return {
        "mu": mu,
        "att_home_avg": att_home_avg,
        "att_away_avg": att_away_avg,
        "def_home_avg": def_home_avg,
        "def_away_avg": def_away_avg,
    }


def calculate_team_intensities(
    team: TeamStrength,
    opponent: TeamStrength,
    is_home: bool,
    league_averages: dict[str, float],
) -> tuple[float, float]:
    """
    Computes (lambda_scored, lambda_conceded) for a team in a fixture per Spec §3.3.

    lambda_scored = mu * (Att(T) / A_avg) * (D_avg / Def(O))
    lambda_conceded = mu * (Att(O) / A_avg) * (D_avg / Def(T))
    """
    mu = league_averages.get("mu", 1.35)

    if is_home:
        att_t = float(team.strength_attack_home)
        a_avg_t = league_averages.get("att_home_avg", 1000.0)

        def_o = float(opponent.strength_defence_away)
        d_avg_o = league_averages.get("def_away_avg", 1000.0)

        att_o = float(opponent.strength_attack_away)
        a_avg_o = league_averages.get("att_away_avg", 1000.0)

        def_t = float(team.strength_defence_home)
        d_avg_t = league_averages.get("def_home_avg", 1000.0)
    else:
        att_t = float(team.strength_attack_away)
        a_avg_t = league_averages.get("att_away_avg", 1000.0)

        def_o = float(opponent.strength_defence_home)
        d_avg_o = league_averages.get("def_home_avg", 1000.0)

        att_o = float(opponent.strength_attack_home)
        a_avg_o = league_averages.get("att_home_avg", 1000.0)

        def_t = float(team.strength_defence_away)
        d_avg_t = league_averages.get("def_away_avg", 1000.0)

    # Avoid division by zero
    def_o = max(1.0, def_o)
    def_t = max(1.0, def_t)
    a_avg_t = max(1.0, a_avg_t)
    a_avg_o = max(1.0, a_avg_o)

    lambda_scored = mu * (att_t / a_avg_t) * (d_avg_o / def_o)
    lambda_conceded = mu * (att_o / a_avg_o) * (d_avg_t / def_t)

    # Safeguard reasonable range
    lambda_scored = max(0.01, lambda_scored)
    lambda_conceded = max(0.01, lambda_conceded)

    return lambda_scored, lambda_conceded
