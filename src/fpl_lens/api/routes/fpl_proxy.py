from typing import Any

from fastapi import APIRouter, Depends, Query, status
from fastapi.responses import JSONResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from fpl_lens.api.deps import get_current_active_user
from fpl_lens.api.errors import AppError
from fpl_lens.config import settings
from fpl_lens.db.models import Gameweek, Player, Team, User
from fpl_lens.db.session import get_db
from fpl_lens.logging import logger
from fpl_lens.services.cache import get_cached_value, get_stale_cached_value, set_cached_value
from fpl_lens.services.fpl_client import UpstreamUnavailableError, fpl_client

router = APIRouter(prefix="/fpl", tags=["FPL Proxy"])


def _verify_team_ownership(user: User, team_id: int) -> None:
    """Enforces that the caller's own team ID is the only one accepted. Other IDs return 404."""
    if user.fpl_team_id != team_id:
        logger.warning(
            "User %s attempted to access team %d (registered team: %s). Rejecting with 404.",
            user.id,
            team_id,
            user.fpl_team_id,
        )
        raise AppError(
            code="FPL_TEAM_NOT_FOUND",
            message="Team not found",
            status_code=status.HTTP_404_NOT_FOUND,
        )


@router.get("/entry/{team_id}")
async def get_team_entry(
    team_id: int,
    user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Returns team and manager details.
    Restricted to caller's own registered team ID (returns 404 otherwise).
    Cached for 1 hour with stale fallback.
    """
    _verify_team_ownership(user, team_id)

    cache_key = f"fpl:entry:{team_id}"
    cached = get_cached_value(db, cache_key)
    if cached is not None:
        return JSONResponse(content=cached, headers={"X-Data-Status": "FRESH"})

    try:
        data = await fpl_client.get_entry(team_id)
        if data is None:
            raise AppError(
                code="FPL_TEAM_NOT_FOUND",
                message="Team not found on FPL upstream",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        set_cached_value(db, cache_key, data, ttl_seconds=settings.FPL_ENTRY_CACHE_TTL_SECONDS)
        return JSONResponse(content=data, headers={"X-Data-Status": "FRESH"})

    except UpstreamUnavailableError as exc:
        logger.warning(
            "FPL upstream error during get_entry(%d): %s. Checking cache fallback.", team_id, exc
        )
        stale = get_stale_cached_value(db, cache_key)
        if stale is not None:
            value, expires_at = stale
            return JSONResponse(
                content=value,
                headers={"X-Data-Status": "STALE", "X-Cached-At": expires_at.isoformat()},
            )
        raise AppError(
            code="UPSTREAM_UNAVAILABLE",
            message="FPL upstream service is currently unavailable",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        ) from exc


@router.get("/entry/{team_id}/squad")
async def get_team_squad(
    team_id: int,
    gw: int | None = Query(default=None, description="Gameweek number"),
    force: bool = Query(default=False, description="Bypass cache"),
    user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Returns picks, captain, vice-captain, and active chip for a gameweek.
    Restricted to caller's own registered team ID.
    Cached for 10 minutes with stale fallback.
    """
    _verify_team_ownership(user, team_id)

    target_gw = gw
    if target_gw is None or target_gw > 38 or target_gw < 1:
        # Resolve current gameweek from DB (official PL gameweeks 1-38)
        stmt: Any = (
            select(Gameweek.id)
            .where(Gameweek.is_current.is_(True), Gameweek.id <= 38)
            .limit(1)
        )
        current_gw_id = db.execute(stmt).scalar_one_or_none()
        target_gw = current_gw_id if current_gw_id is not None else 1

    cache_key = f"fpl:entry:{team_id}:squad:{target_gw}"
    if not force:
        cached = get_cached_value(db, cache_key)
        if cached is not None:
            return JSONResponse(content=cached, headers={"X-Data-Status": "FRESH"})

    try:
        data = await fpl_client.get_picks(team_id, target_gw)
        if data is None:
            # If target_gw has no picks on FPL upstream, fallback to entry.current_event
            entry = await fpl_client.get_entry(team_id)
            cur_event = entry.get("current_event") if entry else None
            if cur_event and cur_event != target_gw and 1 <= cur_event <= 38:
                target_gw = cur_event
                data = await fpl_client.get_picks(team_id, target_gw)

        if data is None:
            raise AppError(
                code="FPL_TEAM_NOT_FOUND",
                message="Squad picks not found for specified team and gameweek",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        # Enrich picks with player details from the database so the frontend has names, teams, and prices
        pick_elements = [p.get("element") for p in data.get("picks", []) if p.get("element")]
        if pick_elements:
            players_stmt: Any = (
                select(Player, Team.short_name)
                .outerjoin(Team, Player.team_fpl_id == Team.fpl_id)
                .where(Player.fpl_id.in_(pick_elements))
            )
            player_rows = db.execute(players_stmt).all()
            player_map = {
                p.fpl_id: {
                    "web_name": p.web_name,
                    "player_position": p.position,
                    "team_fpl_id": p.team_fpl_id,
                    "team_short_name": short_name or "PL",
                    "now_cost": p.now_cost,
                    "status": p.status,
                    "chance_of_playing_next_round": p.chance_of_playing_next_round,
                }
                for p, short_name in player_rows
            }
            for pick in data.get("picks", []):
                pid = pick.get("element")
                if pid in player_map:
                    pick.update(player_map[pid])

        set_cached_value(db, cache_key, data, ttl_seconds=settings.FPL_CACHE_TTL_SECONDS)
        return JSONResponse(content=data, headers={"X-Data-Status": "FRESH"})

    except UpstreamUnavailableError as exc:
        logger.warning(
            "FPL upstream error during get_picks(%d, %d): %s. Checking cache fallback.",
            team_id,
            target_gw,
            exc,
        )
        stale = get_stale_cached_value(db, cache_key)
        if stale is not None:
            value, expires_at = stale
            return JSONResponse(
                content=value,
                headers={"X-Data-Status": "STALE", "X-Cached-At": expires_at.isoformat()},
            )
        raise AppError(
            code="UPSTREAM_UNAVAILABLE",
            message="FPL upstream service is currently unavailable",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        ) from exc


@router.get("/entry/{team_id}/history")
async def get_team_history(
    team_id: int,
    user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Returns gameweek history for caller's team.
    Restricted to caller's own registered team ID.
    Cached for 10 minutes with stale fallback.
    """
    _verify_team_ownership(user, team_id)

    cache_key = f"fpl:entry:{team_id}:history"
    cached = get_cached_value(db, cache_key)
    if cached is not None:
        return JSONResponse(content=cached, headers={"X-Data-Status": "FRESH"})

    try:
        data = await fpl_client.get_history(team_id)
        if data is None:
            raise AppError(
                code="FPL_TEAM_NOT_FOUND",
                message="Team history not found",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        set_cached_value(db, cache_key, data, ttl_seconds=settings.FPL_CACHE_TTL_SECONDS)
        return JSONResponse(content=data, headers={"X-Data-Status": "FRESH"})

    except UpstreamUnavailableError as exc:
        logger.warning(
            "FPL upstream error during get_history(%d): %s. Checking cache fallback.", team_id, exc
        )
        stale = get_stale_cached_value(db, cache_key)
        if stale is not None:
            value, expires_at = stale
            return JSONResponse(
                content=value,
                headers={"X-Data-Status": "STALE", "X-Cached-At": expires_at.isoformat()},
            )
        raise AppError(
            code="UPSTREAM_UNAVAILABLE",
            message="FPL upstream service is currently unavailable",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        ) from exc


@router.get("/entry/{team_id}/transfers")
async def get_team_transfers(
    team_id: int,
    user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Returns transfer history for caller's team.
    Restricted to caller's own registered team ID.
    Cached for 10 minutes with stale fallback.
    """
    _verify_team_ownership(user, team_id)

    cache_key = f"fpl:entry:{team_id}:transfers"
    cached = get_cached_value(db, cache_key)
    if cached is not None:
        return JSONResponse(content=cached, headers={"X-Data-Status": "FRESH"})

    try:
        data = await fpl_client.get_transfers(team_id)
        if data is None:
            raise AppError(
                code="FPL_TEAM_NOT_FOUND",
                message="Team transfers not found",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        # Enrich transfers with player names from database
        element_ids = set()
        for t in data:
            if t.get("element_in"):
                element_ids.add(t["element_in"])
            if t.get("element_out"):
                element_ids.add(t["element_out"])

        if element_ids:
            players_stmt: Any = select(Player.fpl_id, Player.web_name).where(
                Player.fpl_id.in_(list(element_ids))
            )
            names_map = {row[0]: row[1] for row in db.execute(players_stmt).all()}
            for t in data:
                t["element_in_name"] = names_map.get(
                    t.get("element_in"), f"Player #{t.get('element_in')}"
                )
                t["element_out_name"] = names_map.get(
                    t.get("element_out"), f"Player #{t.get('element_out')}"
                )

        set_cached_value(db, cache_key, data, ttl_seconds=settings.FPL_CACHE_TTL_SECONDS)
        return JSONResponse(content=data, headers={"X-Data-Status": "FRESH"})

    except UpstreamUnavailableError as exc:
        logger.warning(
            "FPL upstream error during get_transfers(%d): %s. Checking cache fallback.",
            team_id,
            exc,
        )
        stale = get_stale_cached_value(db, cache_key)
        if stale is not None:
            value, expires_at = stale
            return JSONResponse(
                content=value,
                headers={"X-Data-Status": "STALE", "X-Cached-At": expires_at.isoformat()},
            )
        raise AppError(
            code="UPSTREAM_UNAVAILABLE",
            message="FPL upstream service is currently unavailable",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        ) from exc
