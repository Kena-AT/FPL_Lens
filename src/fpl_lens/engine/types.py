from dataclasses import dataclass, field
from datetime import datetime


@dataclass(frozen=True)
class PlayerMatchHistory:
    """Historical match record for a player."""
    gameweek: int
    was_starter: bool
    minutes: int
    goals_scored: int = 0
    assists: int = 0
    clean_sheets: int = 0
    goals_conceded: int = 0
    defensive_contributions: int = 0
    bps: int = 0
    bonus: int = 0
    yellow_cards: int = 0
    red_cards: int = 0
    total_points: int = 0
    expected_goals: float = 0.0
    expected_assists: float = 0.0
    source_fetched_at: datetime | None = None


@dataclass(frozen=True)
class TeamStrength:
    """Team attacking and defensive strength ratings."""
    fpl_id: int
    name: str
    short_name: str
    strength_attack_home: int
    strength_attack_away: int
    strength_defence_home: int
    strength_defence_away: int


@dataclass(frozen=True)
class FixtureContext:
    """Context for a fixture involving a team."""
    fixture_fpl_id: int
    gameweek: int
    team_fpl_id: int
    opponent_fpl_id: int
    is_home: bool
    kickoff_time: datetime | None = None


@dataclass(frozen=True)
class PlayerFeatures:
    """Player feature data required for projecting a fixture."""
    player_fpl_id: int
    position: str  # 'GK', 'DEF', 'MID', 'FWD'
    status: str    # 'a', 'd', 'i', 's', 'u'
    chance_of_playing_next_round: int | None
    team_fpl_id: int
    xg_90: float
    xa_90: float
    history: list[PlayerMatchHistory] = field(default_factory=list)


@dataclass(frozen=True)
class PlayingTimeScenarios:
    """5-scenario playing time partition per Technical Spec §3.2."""
    p_sa: float   # S_A: No appearance
    p_sb: float   # S_B: Sub under 60m
    p_sc: float   # S_C: Sub 60+m
    p_sd: float   # S_D: Starter under 60m
    p_se: float   # S_E: Starter 60+m
    m_sb: float   # Window for S_B
    m_sc: float   # Window for S_C
    m_sd: float   # Window for S_D
    m_se: float   # Window for S_E
    expected_minutes: float
    p_start: float
    p_sub: float
    p_60_plus_given_start: float
    p_60_plus_given_sub: float
    availability: float


@dataclass(frozen=True)
class ProjectionComponents:
    """Component breakdown of expected points per Technical Spec §4."""
    exp_appearance: float
    exp_goals: float
    exp_assists: float
    exp_clean_sheet: float
    exp_goals_conceded: float  # Non-positive penalty (e.g. -0.45)
    exp_dc: float
    exp_bonus: float
    exp_card_penalty: float    # Positive magnitude to subtract
    expected_points: float


@dataclass(frozen=True)
class FixtureProjection:
    """Calculated projection for a player in a specific fixture."""
    player_fpl_id: int
    fixture_fpl_id: int
    gameweek: int
    availability: float
    p_start: float
    p_sub: float
    p_60_plus_given_start: float
    expected_minutes: float
    components: ProjectionComponents
