from fastapi import APIRouter, Depends, Query, status
from fastapi.responses import JSONResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from fpl_lens.api.deps import get_current_active_user
from fpl_lens.api.errors import AppError
from fpl_lens.config import settings
from fpl_lens.db.models import Gameweek, User
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
        logger.warning("FPL upstream error during get_entry(%d): %s. Checking cache fallback.", team_id, exc)
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
    if target_gw is None:
        # Resolve current gameweek from DB
        stmt = select(Gameweek.id).where(Gameweek.is_current.is_(True)).limit(1)
        current_gw_id = db.execute(stmt).scalar_one_or_none()
        target_gw = current_gw_id if current_gw_id is not None else 1

    cache_key = f"fpl:entry:{team_id}:squad:{target_gw}"
    cached = get_cached_value(db, cache_key)
    if cached is not None:
        return JSONResponse(content=cached, headers={"X-Data-Status": "FRESH"})

    try:
        data = await fpl_client.get_picks(team_id, target_gw)
        if data is None:
            raise AppError(
                code="FPL_TEAM_NOT_FOUND",
                message="Squad picks not found for specified team and gameweek",
                status_code=status.HTTP_404_NOT_FOUND,
            )

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
        logger.warning("FPL upstream error during get_history(%d): %s. Checking cache fallback.", team_id, exc)
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

        set_cached_value(db, cache_key, data, ttl_seconds=settings.FPL_CACHE_TTL_SECONDS)
        return JSONResponse(content=data, headers={"X-Data-Status": "FRESH"})

    except UpstreamUnavailableError as exc:
        logger.warning("FPL upstream error during get_transfers(%d): %s. Checking cache fallback.", team_id, exc)
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
