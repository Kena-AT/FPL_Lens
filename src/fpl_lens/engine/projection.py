"""
Deterministic Layer 1 projection engine orchestrator.
"""

import hashlib
import json

from fpl_lens.engine.availability import calculate_availability
from fpl_lens.engine.components import compute_projection_components
from fpl_lens.engine.intensities import calculate_team_intensities
from fpl_lens.engine.playing_time import calculate_playing_time
from fpl_lens.engine.types import (
    FixtureContext,
    FixtureProjection,
    PlayerFeatures,
    TeamStrength,
)


def compute_inputs_hash(
    gameweek: int,
    players: list[PlayerFeatures],
    fixtures: list[FixtureContext],
    teams: dict[int, TeamStrength],
    league_averages: dict[str, float],
) -> bytes:
    """
    Computes deterministic SHA-256 digest of input rows per Spec & Implementation Plan.
    Identical inputs give identical hashes.
    """
    players_data = [
        {
            "id": p.player_fpl_id,
            "pos": p.position,
            "stat": p.status,
            "chance": p.chance_of_playing_next_round,
            "team": p.team_fpl_id,
            "xg": round(p.xg_90, 4),
            "xa": round(p.xa_90, 4),
            "hist": [
                {
                    "gw": h.gameweek,
                    "min": h.minutes,
                    "start": h.was_starter,
                    "g": h.goals_scored,
                    "a": h.assists,
                    "cs": h.clean_sheets,
                    "gc": h.goals_conceded,
                }
                for h in p.history
            ],
        }
        for p in sorted(players, key=lambda x: x.player_fpl_id)
    ]

    fixtures_data = [
        {
            "fid": f.fixture_fpl_id,
            "gw": f.gameweek,
            "team": f.team_fpl_id,
            "opp": f.opponent_fpl_id,
            "home": f.is_home,
        }
        for f in sorted(fixtures, key=lambda x: (x.gameweek, x.fixture_fpl_id, x.team_fpl_id))
    ]

    teams_data = [
        {
            "id": t.fpl_id,
            "att_h": t.strength_attack_home,
            "att_a": t.strength_attack_away,
            "def_h": t.strength_defence_home,
            "def_a": t.strength_defence_away,
        }
        for _, t in sorted(teams.items())
    ]

    canonical = {
        "gw": gameweek,
        "players": players_data,
        "fixtures": fixtures_data,
        "teams": teams_data,
        "averages": {k: round(v, 6) for k, v in sorted(league_averages.items())},
    }

    serialized = json.dumps(canonical, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(serialized).digest()


def project_player_fixture(
    player: PlayerFeatures,
    fixture: FixtureContext,
    team: TeamStrength,
    opponent: TeamStrength,
    league_averages: dict[str, float],
) -> FixtureProjection:
    """
    Computes a deterministic projection for a single player in a single fixture.
    """
    # 1. Availability alpha(p)
    availability = calculate_availability(player.status, player.chance_of_playing_next_round)

    # 2. Playing-time model (5 scenarios)
    pt = calculate_playing_time(
        availability=availability,
        history=player.history,
        position=player.position,
    )

    # 3. Team intensities
    lambda_scored, lambda_conceded = calculate_team_intensities(
        team=team,
        opponent=opponent,
        is_home=fixture.is_home,
        league_averages=league_averages,
    )

    # 4. Expected points breakdown with strict output validation
    mu = league_averages.get("mu", 1.35)
    components = compute_projection_components(
        pt=pt,
        xg_90=player.xg_90,
        xa_90=player.xa_90,
        lambda_scored=lambda_scored,
        lambda_conceded=lambda_conceded,
        mu=mu,
        position=player.position,
        history=player.history,
        enforce_validation=True,
    )

    return FixtureProjection(
        player_fpl_id=player.player_fpl_id,
        fixture_fpl_id=fixture.fixture_fpl_id,
        gameweek=fixture.gameweek,
        availability=availability,
        p_start=pt.p_start,
        p_sub=pt.p_sub,
        p_60_plus_given_start=pt.p_60_plus_given_start,
        expected_minutes=pt.expected_minutes,
        components=components,
    )


def run_projection_cycle(
    gameweek: int,
    players: list[PlayerFeatures],
    fixtures: list[FixtureContext],
    teams: dict[int, TeamStrength],
    league_averages: dict[str, float],
) -> tuple[list[FixtureProjection], bytes]:
    """
    Runs the full deterministic projection cycle for a gameweek.
    Returns (projections, input_hash).
    """
    # 1. Compute input hash
    input_hash = compute_inputs_hash(gameweek, players, fixtures, teams, league_averages)

    # Map fixtures by team_fpl_id
    team_fixtures: dict[int, list[FixtureContext]] = {}
    for f in fixtures:
        team_fixtures.setdefault(f.team_fpl_id, []).append(f)

    projections: list[FixtureProjection] = []

    for player in players:
        p_fixtures = team_fixtures.get(player.team_fpl_id, [])
        for fix in p_fixtures:
            team = teams.get(fix.team_fpl_id)
            opponent = teams.get(fix.opponent_fpl_id)

            if not team or not opponent:
                continue

            proj = project_player_fixture(
                player=player,
                fixture=fix,
                team=team,
                opponent=opponent,
                league_averages=league_averages,
            )
            projections.append(proj)

    return projections, input_hash
