"""
Squad screenshot resolution request and response schemas per Technical Spec v1.5 §8,
Backend Design §11.3, and Frontend Implementation Plan §D12/P16.
Enforces Backend Design §12.2: extra = 'forbid'.
"""

from pydantic import BaseModel, ConfigDict, Field


class SquadResolvePlayerInput(BaseModel):
    model_config = ConfigDict(extra="forbid")

    raw_name: str = Field(..., min_length=1, max_length=100, description="Raw player name from OCR extraction")
    slot: str | None = Field(None, max_length=32, description="Extracted squad slot, e.g. 'GKP', 'DEF', 'MID', 'FWD', 'Sub 1'")


class SquadResolveRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    players: list[SquadResolvePlayerInput] = Field(
        ...,
        min_length=1,
        max_length=30,
        description="Validated list of player names and slots from on-device extraction",
    )


class PlayerCandidateMatch(BaseModel):
    model_config = ConfigDict(extra="forbid")

    fpl_id: int
    web_name: str
    full_name: str
    team_short_name: str
    position: str
    now_cost: int
    confidence: float
    match_tier: str  # "strong" (>= 0.85), "possible" (0.60 to 0.84), "weak" (< 0.60)


class ResolvedPlayerResult(BaseModel):
    model_config = ConfigDict(extra="forbid")

    raw_name: str
    slot: str | None = None
    candidates: list[PlayerCandidateMatch]
    exact_match: bool
    best_match_fpl_id: int | None = None
    best_confidence: float = 0.0


class SquadResolveResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    results: list[ResolvedPlayerResult]
    all_resolved: bool
    unresolved_count: int
