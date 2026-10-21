import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Request, Response
from sqlalchemy import select
from sqlalchemy.orm import Session

from fpl_lens.api.deps import get_client_ip, get_current_user, get_verified_user
from fpl_lens.api.errors import AppError
from fpl_lens.api.schemas.auth import (
    NotificationPreferencesRequest,
    NotificationPreferencesResponse,
    UserProfileResponse,
)
from fpl_lens.db.models import NotificationPreference, User
from fpl_lens.db.session import get_db
from fpl_lens.services.audit import record_audit_event
from fpl_lens.services.token import revoke_all_user_tokens

router = APIRouter(prefix="/me", tags=["User Profile"])


@router.get("", response_model=UserProfileResponse)
def get_my_profile(
    response: Response,
    current_user: User = Depends(get_current_user),
):
    """Returns profile for the authenticated user (including unverified status)."""
    response.headers["Cache-Control"] = "no-store"
    return UserProfileResponse(
        id=str(current_user.id),
        email=current_user.email,
        display_name=current_user.display_name,
        fpl_team_id=current_user.fpl_team_id,
        status=current_user.status,
        created_at=current_user.created_at.isoformat() if current_user.created_at else "",
    )


@router.get("/notifications", response_model=NotificationPreferencesResponse)
def get_notification_preferences(
    response: Response,
    current_user: User = Depends(get_verified_user),
    db: Session = Depends(get_db),
):
    """
    Reads notification preferences for the authenticated user.
    Creates default preferences if not yet existing.
    """
    response.headers["Cache-Control"] = "no-store"
    stmt = select(NotificationPreference).where(NotificationPreference.user_id == current_user.id)
    pref = db.execute(stmt).scalar_one_or_none()

    if not pref:
        pref = NotificationPreference(
            user_id=current_user.id,
            deadline_reminders=True,
            injury_alerts=True,
            deadline_reminder_hours=6,
        )
        db.add(pref)
        db.commit()

    return NotificationPreferencesResponse(
        deadline_reminders=bool(pref.deadline_reminders),
        injury_alerts=bool(pref.injury_alerts),
        deadline_reminder_hours=int(pref.deadline_reminder_hours),
    )


@router.put("/notifications", response_model=NotificationPreferencesResponse)
def update_notification_preferences(
    payload: NotificationPreferencesRequest,
    response: Response,
    current_user: User = Depends(get_verified_user),
    db: Session = Depends(get_db),
):
    """
    Updates notification preferences for the authenticated user.
    """
    response.headers["Cache-Control"] = "no-store"
    stmt = select(NotificationPreference).where(NotificationPreference.user_id == current_user.id)
    pref = db.execute(stmt).scalar_one_or_none()

    if not pref:
        pref = NotificationPreference(
            user_id=current_user.id,
            deadline_reminders=payload.deadline_reminders,
            injury_alerts=payload.injury_alerts,
            deadline_reminder_hours=payload.deadline_reminder_hours,
        )
        db.add(pref)
    else:
        pref.deadline_reminders = payload.deadline_reminders  # type: ignore[assignment]
        pref.injury_alerts = payload.injury_alerts  # type: ignore[assignment]
        pref.deadline_reminder_hours = payload.deadline_reminder_hours  # type: ignore[assignment]

    db.commit()

    return NotificationPreferencesResponse(
        deadline_reminders=bool(pref.deadline_reminders),
        injury_alerts=bool(pref.injury_alerts),
        deadline_reminder_hours=int(pref.deadline_reminder_hours),
    )


@router.get("/{user_id}", response_model=UserProfileResponse)
def get_user_profile_by_id(
    user_id: uuid.UUID,
    response: Response,
    current_user: User = Depends(get_verified_user),
):
    """
    Enforces authorization check per Backend Design §12.2 and AGENTS.md §9:
    Another user's identifier returns 404 on every account endpoint.
    """
    response.headers["Cache-Control"] = "no-store"
    if current_user.id != user_id:
        raise AppError(
            code="NOT_FOUND",
            message="User not found",
            status_code=404,
        )

    return UserProfileResponse(
        id=str(current_user.id),
        email=current_user.email,
        display_name=current_user.display_name,
        fpl_team_id=current_user.fpl_team_id,
        status=current_user.status,
        created_at=current_user.created_at.isoformat() if current_user.created_at else "",
    )


@router.delete("")
def delete_my_account(
    request: Request,
    response: Response,
    current_user: User = Depends(get_verified_user),
    db: Session = Depends(get_db),
):
    """
    Initiates 3-day account deletion.
    Tokens are revoked immediately, status set to pending_deletion.
    """
    response.headers["Cache-Control"] = "no-store"
    client_ip = get_client_ip(request)

    current_user.status = "pending_deletion"
    current_user.deletion_requested_at = datetime.now(UTC)

    # Immediately revoke all sessions
    revoke_all_user_tokens(db, current_user.id)
    db.commit()

    record_audit_event(
        db=db,
        action="deletion",
        actor_id=str(current_user.id),
        target_id=str(current_user.id),
        ip=client_ip,
    )

    return {
        "message": "Account marked for deletion. Tokens revoked immediately. Permanent cleanup in 3 days."
    }
