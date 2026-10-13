from datetime import datetime
from decimal import Decimal, InvalidOperation
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from fpl_lens.logging import logger


def parse_strict_numeric(value: Any, field_name: str) -> Decimal:
    """
    Strict numeric-string parsing.
    Converts numeric strings or numbers to Decimal.
    A missing, empty, or unparseable value raises ValueError.
    Never defaults to zero.
    """
    if value is None:
        raise ValueError(f"Required numeric field '{field_name}' is None (never defaulted to zero)")

    if isinstance(value, (int, float)):
        return Decimal(str(value))

    if isinstance(value, str):
        cleaned = value.strip()
        if not cleaned:
            raise ValueError(f"Required numeric field '{field_name}' is empty (never defaulted to zero)")
        try:
            parsed = Decimal(cleaned)
            if parsed.is_nan() or parsed.is_infinite():
                raise ValueError(f"Numeric field '{field_name}' has non-finite value '{cleaned}'")
            return parsed
        except InvalidOperation as exc:
            raise ValueError(
                f"Numeric field '{field_name}' failed to parse from string '{cleaned}'"
            ) from exc

    raise ValueError(f"Cannot parse type '{type(value).__name__}' as numeric for '{field_name}'")


class FPLBaseModel(BaseModel):
    """Base model that logs unknown upstream fields and strictly enforces types."""

    model_config = ConfigDict(extra="ignore")

    @model_validator(mode="before")
    @classmethod
    def check_and_log_unknown_fields(cls, data: Any) -> Any:
        if isinstance(data, dict):
            known_fields = set(cls.model_fields.keys())
            unknown_fields = set(data.keys()) - known_fields
            if unknown_fields:
                logger.debug(
                    "FPL schema %s observed unknown fields: %s",
                    cls.__name__,
                    sorted(list(unknown_fields)),
                )
        return data


class FPLTeamSchema(FPLBaseModel):
    id: int
    name: str
    short_name: str
    strength_attack_home: int
    strength_attack_away: int
    strength_defence_home: int
    strength_defence_away: int


class FPLElementSchema(FPLBaseModel):
    id: int
    first_name: str
    second_name: str
    web_name: str
    element_type: int
    team: int
    now_cost: int
    status: str
    chance_of_playing_next_round: int | None = None
    news: str | None = None
    news_added: datetime | None = None
    expected_goals: Decimal = Field(default=Decimal("0.00"))
    expected_assists: Decimal = Field(default=Decimal("0.00"))
    form: Decimal = Field(default=Decimal("0.00"))
    points_per_game: Decimal = Field(default=Decimal("0.00"))
    selected_by_percent: Decimal = Field(default=Decimal("0.00"))

    @field_validator(
        "expected_goals",
        "expected_assists",
        "form",
        "points_per_game",
        "selected_by_percent",
        mode="before",
    )
    @classmethod
    def validate_strict_numerics(cls, v: Any, info) -> Decimal:
        return parse_strict_numeric(v, info.field_name)


class FPLEventSchema(FPLBaseModel):
    id: int
    name: str
    deadline_time: datetime
    finished: bool
    is_current: bool
    is_next: bool


class FPLFixtureSchema(FPLBaseModel):
    id: int
    event: int | None = None
    kickoff_time: datetime | None = None
    team_h: int
    team_a: int
    finished: bool
    team_h_score: int | None = None
    team_a_score: int | None = None


class FPLElementHistorySchema(FPLBaseModel):
    element: int
    fixture: int
    round: int
    starts: int = 0
    minutes: int
    total_points: int
    goals_scored: int
    assists: int
    clean_sheets: int
    goals_conceded: int
    defensive_contribution: int = 0
    bps: int
    bonus: int
    yellow_cards: int
    red_cards: int
    expected_goals: Decimal
    expected_assists: Decimal
    expected_goal_involvements: Decimal
    expected_goals_conceded: Decimal

    @field_validator(
        "expected_goals",
        "expected_assists",
        "expected_goal_involvements",
        "expected_goals_conceded",
        mode="before",
    )
    @classmethod
    def validate_strict_numerics(cls, v: Any, info) -> Decimal:
        return parse_strict_numeric(v, info.field_name)


class FPLEntrySchema(FPLBaseModel):
    id: int
    name: str
    player_first_name: str
    player_last_name: str
    summary_overall_points: int | None = None
    summary_overall_rank: int | None = None
    summary_event_points: int | None = None


class FPLPickItemSchema(FPLBaseModel):
    element: int
    position: int
    multiplier: int
    is_captain: bool
    is_vice_captain: bool


class FPLPicksResponseSchema(FPLBaseModel):
    active_chip: str | None = None
    entry_history: dict[str, Any]
    picks: list[FPLPickItemSchema]


class FPLHistoryResponseSchema(FPLBaseModel):
    current: list[dict[str, Any]]
    past: list[dict[str, Any]]
    chips: list[dict[str, Any]]


class FPLTransferItemSchema(FPLBaseModel):
    element_in: int
    element_in_cost: int
    element_out: int
    element_out_cost: int
    entry: int
    event: int
    time: str
