from typing import Any

from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from sqlalchemy import func, select, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from fpl_lens.db.models import IngestionRun, PublishedProjection
from fpl_lens.db.session import get_db
from fpl_lens.logging import logger

router = APIRouter(tags=["Health"])


@router.get("/health")
def health_check(db: Session = Depends(get_db)) -> JSONResponse:
    """
    Health check endpoint reporting database reachability and the timestamps
    of the last successful ingestion and projection runs.
    """
    db_status = "connected"
    last_ingestion_at: str | None = None
    last_projection_at: str | None = None

    try:
        # Check database connectivity
        db.execute(text("SELECT 1;")).scalar()

        # Query last successful ingestion timestamp
        ingestion_stmt = (
            select(func.max(IngestionRun.finished_at))
            .where(IngestionRun.status == "OK")
        )
        last_ingestion = db.execute(ingestion_stmt).scalar()
        if last_ingestion:
            last_ingestion_at = last_ingestion.isoformat()

        # Query last published projection timestamp
        proj_stmt = select(func.max(PublishedProjection.published_at))
        last_proj = db.execute(proj_stmt).scalar()
        if last_proj:
            last_projection_at = last_proj.isoformat()

        payload: dict[str, Any] = {
            "status": "ok",
            "database": db_status,
            "last_ingestion_at": last_ingestion_at,
            "last_projection_at": last_projection_at,
        }
        return JSONResponse(status_code=status.HTTP_200_OK, content=payload)

    except SQLAlchemyError as exc:
        logger.error("Health check database failure: %s", exc)
        payload = {
            "status": "degraded",
            "database": "unreachable",
            "last_ingestion_at": None,
            "last_projection_at": None,
        }
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content=payload,
        )
