"""
Squad resolution route per Backend Design §11.3, Technical Spec v1.5 §8,
and AGENTS.md §8 (Privacy & Data Handling).

Accepts the on-device extraction JSON of names/slots and resolves against the player table.
Enforces that the server NEVER receives screenshot images or raw photo files.
Logs must not contain player names or personal squad details.
"""

import difflib
import re
import unicodedata
from typing import Any

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from fpl_lens.api.deps import get_current_active_user
from fpl_lens.api.schemas.squads import (
    PlayerCandidateMatch,
    ResolvedPlayerResult,
    SquadResolveRequest,
    SquadResolveResponse,
)
from fpl_lens.db.models import Player, Team, User
from fpl_lens.db.session import get_db
from fpl_lens.logging import logger

router = APIRouter(prefix="/squads", tags=["Squads"])


def _normalize_name(name: str) -> str:
    """Strips accents, lowercase, removes punctuation for robust OCR matching."""
    nfkd = unicodedata.normalize("NFKD", name)
    ascii_str = nfkd.encode("ASCII", "ignore").decode("utf-8")
    cleaned = re.sub(r"[^a-zA-Z0-9\s]", "", ascii_str).strip().lower()
    return re.sub(r"\s+", " ", cleaned)


def _position_from_slot(slot: str | None) -> str | None:
    if not slot:
        return None
    s = slot.upper()
    if "GK" in s or "GOAL" in s:
        return "GK"
    if "DEF" in s or "BACK" in s:
        return "DEF"
    if "MID" in s:
        return "MID"
    if "FWD" in s or "ATT" in s or "STRIKER" in s:
        return "FWD"
    return None


@router.post(
    "/resolve",
    response_model=SquadResolveResponse,
    status_code=status.HTTP_200_OK,
    summary="Resolve extracted OCR player names to FPL IDs",
)
def resolve_squad_names(
    payload: SquadResolveRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> SquadResolveResponse:
    """
    Resolves OCR-extracted names to FPL IDs with confidence percentages and tiers.
    Accepts only the validated text list; never receives screenshots (AGENTS.md §8).
    """
    # Fetch all active players with team short names
    stmt: Any = (
        select(Player, Team.short_name)
        .join(Team, Team.fpl_id == Player.team_fpl_id)
        .where(Player.status != "u")
    )
    db_players = db.execute(stmt).all()

    player_records: list[dict[str, Any]] = []
    for player, team_short in db_players:
        norm_web = _normalize_name(player.web_name)
        norm_first = _normalize_name(player.first_name)
        norm_second = _normalize_name(player.second_name)
        norm_full = f"{norm_first} {norm_second}".strip()
        player_records.append(
            {
                "player": player,
                "team_short": team_short,
                "norm_web": norm_web,
                "norm_first": norm_first,
                "norm_second": norm_second,
                "norm_full": norm_full,
            }
        )

    results: list[ResolvedPlayerResult] = []

    for item in payload.players:
        raw_clean = _normalize_name(item.raw_name)
        expected_pos = _position_from_slot(item.slot)
        scored_candidates: list[tuple[float, dict[str, Any]]] = []

        for p_rec in player_records:
            # Check exact match candidates
            if raw_clean == p_rec["norm_web"] or raw_clean == p_rec["norm_full"]:
                score = 1.0
            elif raw_clean == p_rec["norm_second"]:
                score = 0.96
            elif p_rec["norm_second"].startswith(raw_clean) and len(raw_clean) >= 4:
                score = 0.90
            elif raw_clean in p_rec["norm_full"] and len(raw_clean) >= 4:
                score = 0.88
            else:
                # Fuzzy ratio matching across web_name, full_name, and second_name
                r_web = difflib.SequenceMatcher(None, raw_clean, p_rec["norm_web"]).ratio()
                r_full = difflib.SequenceMatcher(None, raw_clean, p_rec["norm_full"]).ratio()
                r_second = difflib.SequenceMatcher(None, raw_clean, p_rec["norm_second"]).ratio()
                score = max(r_web, r_full, r_second)

            # Slot position compatibility bonus / penalty
            if expected_pos and score > 0.5:
                if p_rec["player"].position == expected_pos:
                    score = min(1.0, score + 0.05)
                else:
                    score = max(0.0, score - 0.08)

            if score >= 0.40:
                scored_candidates.append((score, p_rec))

        # Sort top candidates by score descending
        scored_candidates.sort(key=lambda x: x[0], reverse=True)
        top_candidates = scored_candidates[:3]

        candidate_matches: list[PlayerCandidateMatch] = []
        for score, p_rec in top_candidates:
            p = p_rec["player"]
            if score >= 0.85:
                tier = "strong"
            elif score >= 0.60:
                tier = "possible"
            else:
                tier = "weak"

            candidate_matches.append(
                PlayerCandidateMatch(
                    fpl_id=p.fpl_id,
                    web_name=p.web_name,
                    full_name=f"{p.first_name} {p.second_name}",
                    team_short_name=p_rec["team_short"],
                    position=p.position,
                    now_cost=p.now_cost,
                    confidence=round(score, 3),
                    match_tier=tier,
                )
            )

        best_score = top_candidates[0][0] if top_candidates else 0.0
        best_id = (
            top_candidates[0][1]["player"].fpl_id if top_candidates and best_score >= 0.60 else None
        )
        exact = best_score >= 0.85

        results.append(
            ResolvedPlayerResult(
                raw_name=item.raw_name,
                slot=item.slot,
                candidates=candidate_matches,
                exact_match=exact,
                best_match_fpl_id=best_id,
                best_confidence=round(best_score, 3),
            )
        )

    all_resolved = len(results) == len(payload.players) and all(r.exact_match for r in results)
    unresolved_count = sum(1 for r in results if not r.exact_match)

    # Privacy: Log count and metrics only, never log player names or squad contents
    logger.info(
        "Squad resolve completed for user %s: %d players submitted, %d resolved, %d unclear",
        current_user.id,
        len(payload.players),
        len(payload.players) - unresolved_count,
        unresolved_count,
    )

    return SquadResolveResponse(
        results=results,
        all_resolved=all_resolved,
        unresolved_count=unresolved_count,
    )
