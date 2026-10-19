import hmac

from fastapi import APIRouter, Depends, Header, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from fpl_lens.api.errors import AppError
from fpl_lens.config import settings
from fpl_lens.db.session import get_db
from fpl_lens.logging import logger
from fpl_lens.services.ingestion import (
    run_bootstrap_job,
    run_cleanup_job,
    run_fixtures_job,
    run_history_job,
)

router = APIRouter(prefix="/internal/jobs", tags=["Internal Jobs"])


def verify_job_token(
    x_job_token: str | None = Header(default=None, alias="X-Job-Token"),
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> None:
    """
    Enforces constant-time job token comparison per Backend Design §8.1.
    Rejects requests without valid token with 401.
    """
    provided = x_job_token
    if not provided and authorization and authorization.startswith("Bearer "):
        provided = authorization.replace("Bearer ", "", 1).strip()

    expected = settings.get_effective_job_token()

    if not provided or not expected:
        logger.warning("Internal job request rejected: missing job token")
        raise AppError(
            code="UNAUTHENTICATED",
            message="Missing job token",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    if not hmac.compare_digest(provided.encode("utf-8"), expected.encode("utf-8")):
        logger.warning("Internal job request rejected: invalid job token")
        raise AppError(
            code="UNAUTHENTICATED",
            message="Invalid job token",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )


@router.post("/{name}")
async def trigger_internal_job(
    name: str,
    _: None = Depends(verify_job_token),
    db: Session = Depends(get_db),
):
    """
    Triggers an internal background ingestion job by name.
    Supported jobs: bootstrap, fixtures, history, cleanup.
    """
    logger.info("Internal job triggered: %s", name)

    if name == "bootstrap":
        result = await run_bootstrap_job(db)
        return JSONResponse(status_code=status.HTTP_200_OK, content=result)

    if name == "fixtures":
        result = await run_fixtures_job(db)
        return JSONResponse(status_code=status.HTTP_200_OK, content=result)

    if name == "history":
        result = await run_history_job(db)
        return JSONResponse(status_code=status.HTTP_200_OK, content=result)

    if name == "cleanup":
        result = await run_cleanup_job(db)
        return JSONResponse(status_code=status.HTTP_200_OK, content=result)

    if name == "project":
        from fpl_lens.engine.service import run_projection_job

        result = run_projection_job(db)
        return JSONResponse(status_code=status.HTTP_200_OK, content=result)

    raise AppError(
        code="NOT_FOUND",
        message=f"Unknown internal job '{name}'",
        status_code=status.HTTP_404_NOT_FOUND,
    )
