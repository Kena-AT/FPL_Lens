"""
Projections and reference API routes per Backend Design §7.2, §11.2.
Serves published projection bundles, player lookups, current gameweeks, fixtures, and player search.
"""

import hashlib
import json
from typing import Any, cast

from fastapi import APIRouter, Depends, Header, Query, Response, status
from fastapi.responses import JSONResponse
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from fpl_lens.api.deps import get_current_active_user
from fpl_lens.api.errors import AppError
from fpl_lens.db.models import Fixture, Gameweek, Player, PublishedProjection, User
from fpl_lens.db.session import get_db
from fpl_lens.logging import logger

router = APIRouter(tags=["Projections & Reference"])


def _compute_etag(content: dict[str, Any]) -> str:
    """Computes an ETag from JSON content."""
    serialized = json.dumps(content, sort_keys=True).encode("utf-8")
    digest = hashlib.sha256(serialized).hexdigest()[:16]
    return f'"{digest}"'


@router.get("/projections/{gw}")
def get_projection_bundle(
    gw: int,
    if_none_match: str | None = Header(default=None, alias="If-None-Match"),
    db: Session = Depends(get_db),
) -> Response:
    """
    Returns the published projection bundle for gameweek `gw`.
    Served directly from published_projections table without recomputing.
    Supports ETag and 304 Not Modified.
    """
    logger.info("Fetching published projection bundle for GW %d", gw)
    pub = db.query(PublishedProjection).filter(PublishedProjection.gameweek == gw).first()
    if not pub:
        logger.warning("No published projections found for GW %d", gw)
        raise AppError(
            code="PROJECTIONS_UNAVAILABLE",
            message=f"Projections for gameweek {gw} are not yet published",
            status_code=status.HTTP_404_NOT_FOUND,
        )

    bundle = cast(dict[str, Any], pub.bundle_json)
    etag = _compute_etag(bundle)

    # Check ETag match
    if if_none_match:
        # Strip weak validator prefix if present
        client_etags = [t.strip().strip("W/") for t in if_none_match.split(",")]
        cleaned_etag = etag.strip("W/")
        if cleaned_etag in client_etags or "*" in client_etags:
            return Response(
                status_code=status.HTTP_304_NOT_MODIFIED,
                headers={
                    "ETag": etag,
                    "Cache-Control": "public, max-age=300",
                },
            )

    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content=bundle,
        headers={
            "ETag": etag,
            "Cache-Control": "public, max-age=300",
        },
    )


@router.get("/projections/{gw}/players/{fpl_id}")
def get_player_projection(
    gw: int,
    fpl_id: int,
    db: Session = Depends(get_db),
) -> JSONResponse:
    """
    Returns projection details for a specific player in gameweek `gw`.
    Extracted from the published projection bundle.
    """
    pub = db.query(PublishedProjection).filter(PublishedProjection.gameweek == gw).first()
    if not pub:
        raise AppError(
            code="PROJECTIONS_UNAVAILABLE",
            message=f"Projections for gameweek {gw} are not yet published",
            status_code=status.HTTP_404_NOT_FOUND,
        )

    bundle = cast(dict[str, Any], pub.bundle_json)
    players = bundle.get("players", [])
    player_data = next((p for p in players if p.get("fpl_id") == fpl_id), None)

    if not player_data:
        raise AppError(
            code="NOT_FOUND",
            message=f"Player {fpl_id} not found in GW {gw} projections",
            status_code=status.HTTP_404_NOT_FOUND,
        )

    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={
            "gameweek": gw,
            "fpl_id": fpl_id,
            "model_version": bundle.get("model_version"),
            "inputs_as_of": bundle.get("inputs_as_of"),
            "fixtures": player_data.get("fixtures", []),
        },
        headers={"Cache-Control": "public, max-age=300"},
    )


@router.get("/gameweeks/current")
def get_current_gameweek(db: Session = Depends(get_db)) -> JSONResponse:
    """
    Returns current and next gameweek metadata.
    """
    current_gw = db.query(Gameweek).filter(Gameweek.is_current.is_(True)).first()
    next_gw = db.query(Gameweek).filter(Gameweek.is_next.is_(True)).first()

    if not current_gw and not next_gw:
        # Fallback to earliest unfinished gameweek
        next_gw = db.query(Gameweek).filter(Gameweek.finished.is_(False)).order_by(Gameweek.id.asc()).first()

    def serialize_gw(gw: Gameweek | None) -> dict[str, Any] | None:
        if not gw:
            return None
        return {
            "id": gw.id,
            "name": gw.name,
            "deadline_time": gw.deadline_time.isoformat() if gw.deadline_time else None,
            "finished": gw.finished,
            "is_current": gw.is_current,
            "is_next": gw.is_next,
        }

    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={
            "current": serialize_gw(current_gw),
            "next": serialize_gw(next_gw),
        },
        headers={"Cache-Control": "public, max-age=60"},
    )


@router.get("/fixtures")
def get_fixtures(
    gw: int | None = Query(default=None, description="Gameweek filter"),
    db: Session = Depends(get_db),
) -> JSONResponse:
    """
    Returns Premier League fixtures, optionally filtered by gameweek.
    """
    query = db.query(Fixture)
    if gw is not None:
        query = query.filter(Fixture.gameweek == gw)

    fixtures = query.order_by(Fixture.kickoff_time.asc().nulls_last()).all()

    payload = [
        {
            "fpl_id": f.fpl_id,
            "gameweek": f.gameweek,
            "kickoff_time": f.kickoff_time.isoformat() if f.kickoff_time else None,
            "home_team_fpl_id": f.home_team_fpl_id,
            "away_team_fpl_id": f.away_team_fpl_id,
            "finished": f.finished,
            "home_score": f.home_score,
            "away_score": f.away_score,
        }
        for f in fixtures
    ]

    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content=payload,
        headers={"Cache-Control": "public, max-age=300"},
    )


@router.get("/players/search")
def search_players(
    q: str = Query(default="", min_length=0, description="Player name search query"),
    limit: int = Query(default=10, ge=1, le=50, description="Max results"),
    _: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> JSONResponse:
    """
    Name lookup used for screenshot resolution and manual squad entry per Backend Design §11.2.
    Requires authenticated user.
    """
    clean_q = q.strip()
    if clean_q:
        search_term = f"%{clean_q}%"
        stmt = (
            select(Player)
            .where(
                or_(
                    Player.web_name.ilike(search_term),
                    Player.first_name.ilike(search_term),
                    Player.second_name.ilike(search_term),
                )
            )
            .limit(limit)
        )
    else:
        stmt = select(Player).order_by(Player.now_cost.desc()).limit(limit)

    players = db.execute(stmt).scalars().all()

    payload = [
        {
            "fpl_id": p.fpl_id,
            "web_name": p.web_name,
            "first_name": p.first_name,
            "second_name": p.second_name,
            "position": p.position,
            "team_fpl_id": p.team_fpl_id,
            "now_cost": p.now_cost,
            "status": p.status,
            "chance_of_playing_next_round": p.chance_of_playing_next_round,
        }
        for p in players
    ]

    return JSONResponse(status_code=status.HTTP_200_OK, content=payload)
