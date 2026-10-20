import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Response, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from fpl_lens.api.deps import get_verified_user
from fpl_lens.api.errors import AppError
from fpl_lens.db.models import Device, User
from fpl_lens.db.session import get_db

router = APIRouter(prefix="/devices", tags=["Devices"])


class DeviceRegistrationRequest(BaseModel):
    fcm_token: str = Field(..., min_length=10, max_length=1024)
    platform: str = Field(default="android", max_length=16)


class DeviceResponse(BaseModel):
    id: str
    fcm_token: str
    platform: str
    created_at: str


@router.post("", response_model=DeviceResponse, status_code=status.HTTP_200_OK)
def register_device(
    payload: DeviceRegistrationRequest,
    response: Response,
    current_user: User = Depends(get_verified_user),
    db: Session = Depends(get_db),
):
    """
    Registers or refreshes an FCM device token for push notifications.
    Access-token protected.
    """
    response.headers["Cache-Control"] = "no-store"
    now = datetime.now(UTC)

    # Check if this FCM token was already registered
    stmt = select(Device).where(Device.fcm_token == payload.fcm_token)
    existing_device = db.execute(stmt).scalar_one_or_none()

    if existing_device:
        existing_device.user_id = current_user.id  # type: ignore[assignment]
        existing_device.platform = payload.platform  # type: ignore[assignment]
        existing_device.last_seen_at = now  # type: ignore[assignment]
        db.commit()
        return DeviceResponse(
            id=str(existing_device.id),
            fcm_token=str(existing_device.fcm_token),
            platform=str(existing_device.platform),
            created_at=existing_device.created_at.isoformat()
            if existing_device.created_at
            else now.isoformat(),
        )

    device_id = uuid.uuid4()
    new_device = Device(
        id=device_id,
        user_id=current_user.id,
        fcm_token=payload.fcm_token,
        platform=payload.platform,
        last_seen_at=now,
        created_at=now,
    )
    db.add(new_device)
    db.commit()

    return DeviceResponse(
        id=str(new_device.id),
        fcm_token=str(new_device.fcm_token),
        platform=str(new_device.platform),
        created_at=now.isoformat(),
    )


@router.delete("/{device_id}", status_code=status.HTTP_200_OK)
def unregister_device(
    device_id: uuid.UUID,
    response: Response,
    current_user: User = Depends(get_verified_user),
    db: Session = Depends(get_db),
):
    """
    Unregisters a device by device ID.
    Enforces authorization check: returns 404 if the device does not belong to the user.
    """
    response.headers["Cache-Control"] = "no-store"
    stmt = select(Device).where(Device.id == device_id, Device.user_id == current_user.id)
    device = db.execute(stmt).scalar_one_or_none()
    if not device:
        raise AppError(
            code="NOT_FOUND",
            message="Device not found",
            status_code=status.HTTP_404_NOT_FOUND,
        )

    db.delete(device)
    db.commit()
    return {"message": "Device unregistered successfully"}
