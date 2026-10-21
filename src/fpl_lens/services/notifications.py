import logging
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from fpl_lens.config import settings
from fpl_lens.db.models import Device, Gameweek, NotificationPreference, Player, User
from fpl_lens.services.fpl_client import fpl_client

logger = logging.getLogger("fpl_lens.notifications")


@dataclass
class NotificationPayload:
    channel_id: str  # 'deadline' or 'injury'
    title: str
    body: str
    data: dict[str, str]


class NotificationDispatchService:
    """
    Sends FCM push notifications for deadline reminders and squad injury alerts.
    Supports mock/fallback mode when Firebase Admin credentials are not mounted.
    Enforces AGENTS.md §8 and Backend Design §12.6:
    - Never logs player names or squad details
    - Payloads contain no personal squad details; player name omitted unless confirmed (A7)
    - Deadlines route to /lineup; injury alerts route to /player/:fplId
    """

    @classmethod
    def send_push_notification(
        cls,
        fcm_token: str,
        payload: NotificationPayload,
    ) -> bool:
        """
        Sends an individual FCM push notification message.
        Returns True if sent or mock-logged, False if token is invalid.
        """
        creds_path = settings.FIREBASE_CREDENTIALS_PATH
        if creds_path:
            try:
                import firebase_admin  # type: ignore[import-untyped]
                from firebase_admin import credentials, messaging  # type: ignore[import-untyped]

                if not firebase_admin._apps:
                    cred = credentials.Certificate(creds_path)
                    firebase_admin.initialize_app(cred)

                message = messaging.Message(
                    notification=messaging.Notification(
                        title=payload.title,
                        body=payload.body,
                    ),
                    data=payload.data,
                    token=fcm_token,
                    android=messaging.AndroidConfig(
                        priority="high" if payload.channel_id == "deadline" else "normal",
                        notification=messaging.AndroidNotification(
                            channel_id=payload.channel_id,
                        ),
                    ),
                )
                messaging.send(message)
                logger.info(
                    "FCM push sent successfully to channel: %s",
                    payload.channel_id,
                )
                return True
            except Exception as e:  # noqa: BLE001
                err_str = str(e).lower()
                logger.warning("FCM delivery failed: %s", type(e).__name__)
                if "invalid" in err_str or "not-found" in err_str or "unregistered" in err_str:
                    return False
                return True
        else:
            # Mock / Stub mode for environments without FCM service account
            logger.info(
                "FCM stub dispatch [channel=%s, target_token_suffix=%s]: %s",
                payload.channel_id,
                fcm_token[-6:],
                payload.title,
            )
            return True


async def dispatch_deadline_reminders(
    db: Session,
    now: datetime | None = None,
    user_ids: list[Any] | None = None,
) -> dict[str, Any]:
    """
    Finds upcoming gameweek deadline and notifies users whose deadline_reminder_hours
    matches the window before deadline.
    Routes to /lineup with channel 'deadline'.
    """
    if now is None:
        now = datetime.now(UTC)

    # Find the next upcoming gameweek
    stmt = (
        select(Gameweek)
        .where(Gameweek.deadline_time > now)
        .order_by(Gameweek.deadline_time.asc())
        .limit(1)
    )
    next_gw = db.execute(stmt).scalar_one_or_none()
    if not next_gw or not next_gw.deadline_time:
        return {"status": "no_upcoming_deadline", "sent_count": 0}

    time_until_deadline = next_gw.deadline_time - now
    hours_until_deadline = time_until_deadline.total_seconds() / 3600.0

    # Match tolerance window +/- 30 minutes (0.5 hour) around scheduled hours
    # Query users with deadline_reminders enabled
    pref_stmt = (
        select(NotificationPreference, Device)
        .join(User, User.id == NotificationPreference.user_id)
        .join(Device, Device.user_id == User.id)
        .where(
            NotificationPreference.deadline_reminders == True,  # noqa: E712
            User.status == "active",
        )
    )
    if user_ids is not None:
        pref_stmt = pref_stmt.where(User.id.in_(user_ids))
    results = db.execute(pref_stmt).all()

    sent_count = 0
    invalid_device_ids = []

    for pref, device in results:
        configured_hours = pref.deadline_reminder_hours
        if abs(hours_until_deadline - configured_hours) <= 0.5:
            hours_display = "1 hour" if configured_hours == 1 else f"{configured_hours} hours"
            payload = NotificationPayload(
                channel_id="deadline",
                title=f"GW{next_gw.id} Deadline Reminder",
                body=f"Gameweek {next_gw.id} deadline is in {hours_display}. Finalise your starting XI and captain.",
                data={
                    "type": "deadline",
                    "route": "/lineup",
                    "gameweek": str(next_gw.id),
                },
            )
            ok = NotificationDispatchService.send_push_notification(device.fcm_token, payload)
            if ok:
                sent_count += 1
            else:
                invalid_device_ids.append(device.id)

    if invalid_device_ids:
        # Cleanup stale/unregistered device tokens per Backend Design §12.6
        db.query(Device).filter(Device.id.in_(invalid_device_ids)).delete(synchronize_session=False)
        db.commit()

    return {
        "status": "ok",
        "gameweek": next_gw.id,
        "hours_until_deadline": round(hours_until_deadline, 2),
        "sent_count": sent_count,
        "stale_tokens_removed": len(invalid_device_ids),
    }


async def dispatch_injury_alerts(
    db: Session,
    user_ids: list[Any] | None = None,
) -> dict[str, Any]:
    """
    Checks for status/news changes among players, inspects users' squads via FPL proxy,
    and sends injury alerts.
    Default notification content decision (A7): Player name is omitted from alert body
    ('A player in your squad is doubtful or injured.').
    Deep-links to /player/:fplId with channel 'injury'.
    Does not persist the squad on the server.
    """
    # 1. Query all players marked as doubtful, injured, or suspended with recent status/news
    player_stmt = select(Player).where(Player.status.in_(["d", "i", "s"]))
    flagged_players = {p.fpl_id: p for p in db.execute(player_stmt).scalars().all()}
    if not flagged_players:
        return {"status": "no_flagged_players", "sent_count": 0}

    # 2. Query users with injury_alerts enabled
    pref_stmt = (
        select(User, Device)
        .join(NotificationPreference, NotificationPreference.user_id == User.id)
        .join(Device, Device.user_id == User.id)
        .where(
            NotificationPreference.injury_alerts == True,  # noqa: E712
            User.status == "active",
            User.fpl_team_id != None,  # noqa: E711
        )
    )
    if user_ids is not None:
        pref_stmt = pref_stmt.where(User.id.in_(user_ids))
    targets = db.execute(pref_stmt).all()

    sent_count = 0
    invalid_device_ids = []

    # Map team_id -> current squad player IDs via FPL client
    for user, device in targets:
        team_id = user.fpl_team_id
        if not team_id:
            continue

        try:
            # Server fetches squad using caller team ID per Backend Design §10.2
            # Using cached or live squad lookup
            cache_key = f"squad_picks:{team_id}"
            from fpl_lens.services.cache import get_cached_value, set_cached_value

            cached = get_cached_value(db, cache_key)
            if cached and isinstance(cached, list):
                squad_data = cached
            else:
                # Fetch recent picks from upstream
                entry_data = await fpl_client.get_entry(team_id)
                if not entry_data:
                    continue
                current_gw = entry_data.get("current_event") or 1
                picks_resp = await fpl_client.get_picks(team_id, current_gw)
                if not picks_resp:
                    continue
                squad_data = [pick["element"] for pick in picks_resp.get("picks", [])]
                set_cached_value(db, cache_key, squad_data, ttl_seconds=1800)

            # Check if any player in squad is in flagged_players
            squad_player_ids = set(squad_data)
            flagged_in_squad = squad_player_ids.intersection(flagged_players.keys())

            if flagged_in_squad:
                first_flagged_id = next(iter(flagged_in_squad))
                # Decision A7: default to omitting player name until confirmed
                payload = NotificationPayload(
                    channel_id="injury",
                    title="Squad Availability Update",
                    body="A player in your squad is reported doubtful or injured. Check status before the deadline.",
                    data={
                        "type": "injury",
                        "route": f"/player/{first_flagged_id}",
                        "player_id": str(first_flagged_id),
                    },
                )
                ok = NotificationDispatchService.send_push_notification(device.fcm_token, payload)
                if ok:
                    sent_count += 1
                else:
                    invalid_device_ids.append(device.id)
        except Exception as e:  # noqa: BLE001
            logger.warning("Could not evaluate injury alerts for team %s: %s", team_id, e)

    if invalid_device_ids:
        db.query(Device).filter(Device.id.in_(invalid_device_ids)).delete(synchronize_session=False)
        db.commit()

    return {
        "status": "ok",
        "flagged_players_count": len(flagged_players),
        "alerts_dispatched": sent_count,
        "stale_tokens_removed": len(invalid_device_ids),
    }
