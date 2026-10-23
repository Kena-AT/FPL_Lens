import secrets
import uuid
from datetime import UTC, datetime, timedelta
from unittest.mock import patch

import pytest
from sqlalchemy.orm import Session

from fpl_lens.db.models import Device, Gameweek, NotificationPreference, Player, Team, User
from fpl_lens.services.notifications import (
    NotificationDispatchService,
    dispatch_deadline_reminders,
    dispatch_injury_alerts,
)


@pytest.mark.asyncio
async def test_dispatch_deadline_reminders_exact_timing(db_session: Session):
    tag = uuid.uuid4().hex[:6]
    now = datetime(2026, 10, 24, 12, 0, 0, tzinfo=UTC)

    # Gameweek deadline in exactly 6 hours
    gw = Gameweek(
        id=99,
        name="Gameweek 99",
        deadline_time=now + timedelta(hours=6),
        is_current=False,
        is_next=True,
        finished=False,
    )
    db_session.merge(gw)
    db_session.commit()

    import secrets

    team1 = secrets.randbelow(1_000_000) + 7_000_000
    team2 = team1 + 1

    user1 = User(
        id=uuid.uuid4(),
        email=f"user1_{tag}@example.com",
        fpl_team_id=team1,
        status="active",
        email_verified_at=now,
    )
    user2 = User(
        id=uuid.uuid4(),
        email=f"user2_{tag}@example.com",
        fpl_team_id=team2,
        status="active",
        email_verified_at=now,
    )
    db_session.add_all([user1, user2])
    db_session.commit()

    # User 1 wants 6h reminder; User 2 wants 24h reminder
    pref1 = NotificationPreference(
        user_id=user1.id,
        deadline_reminders=True,
        deadline_reminder_hours=6,
    )
    pref2 = NotificationPreference(
        user_id=user2.id,
        deadline_reminders=True,
        deadline_reminder_hours=24,
    )
    dev1 = Device(
        id=uuid.uuid4(),
        user_id=user1.id,
        fcm_token=f"token_u1_{tag}_6hours",
        platform="android",
    )
    dev2 = Device(
        id=uuid.uuid4(),
        user_id=user2.id,
        fcm_token=f"token_u2_{tag}_24hours",
        platform="android",
    )
    db_session.add_all([pref1, pref2, dev1, dev2])
    db_session.commit()

    with patch.object(
        NotificationDispatchService, "send_push_notification", return_value=True
    ) as mock_send:
        result = await dispatch_deadline_reminders(
            db_session, now=now, user_ids=[user1.id, user2.id]
        )

        assert result["status"] == "ok"
        assert result["gameweek"] == 99
        # User 1 matches (6h); User 2 does not match (24h)
        assert mock_send.call_count == 1
        call_args = mock_send.call_args[0]
        assert call_args[0] == dev1.fcm_token
        assert call_args[1].channel_id == "deadline"
        assert call_args[1].data["route"] == "/lineup"
        assert "6 hours" in call_args[1].body


@pytest.mark.asyncio
async def test_dispatch_injury_alerts_decision_a7(db_session: Session):
    tag = uuid.uuid4().hex[:6]
    now = datetime.now(UTC)

    # 1. Setup Team and Flagged Player
    team = Team(
        fpl_id=89,
        name="Test FC",
        short_name="TFC",
        strength_attack_home=1000,
        strength_attack_away=1000,
        strength_defence_home=1000,
        strength_defence_away=1000,
    )
    db_session.merge(team)
    db_session.commit()

    flagged_player = Player(
        fpl_id=9901,
        first_name="Kevin",
        second_name="Injured",
        web_name="InjuredK",
        position="MID",
        team_fpl_id=89,
        now_cost=100,
        status="d",  # Doubtful
        news="Hamstring strain - 50% chance of playing",
    )
    healthy_player = Player(
        fpl_id=9902,
        first_name="Jack",
        second_name="Fit",
        web_name="FitJ",
        position="FWD",
        team_fpl_id=89,
        now_cost=80,
        status="a",  # Available
    )
    db_session.merge(flagged_player)
    db_session.merge(healthy_player)
    db_session.commit()

    # 2. User A owns flagged player; User B owns healthy player only
    team_a = secrets.randbelow(1_000_000) + 8_000_000
    team_b = team_a + 1

    user_a = User(
        id=uuid.uuid4(),
        email=f"owner_a_{tag}@example.com",
        fpl_team_id=team_a,
        status="active",
        email_verified_at=now,
    )
    user_b = User(
        id=uuid.uuid4(),
        email=f"owner_b_{tag}@example.com",
        fpl_team_id=team_b,
        status="active",
        email_verified_at=now,
    )
    db_session.add_all([user_a, user_b])
    db_session.commit()

    pref_a = NotificationPreference(user_id=user_a.id, injury_alerts=True)
    pref_b = NotificationPreference(user_id=user_b.id, injury_alerts=True)
    dev_a = Device(id=uuid.uuid4(), user_id=user_a.id, fcm_token=f"tok_a_{tag}", platform="android")
    dev_b = Device(id=uuid.uuid4(), user_id=user_b.id, fcm_token=f"tok_b_{tag}", platform="android")
    db_session.add_all([pref_a, pref_b, dev_a, dev_b])
    db_session.commit()

    # Mock FPL proxy / upstream squad responses
    async def mock_get_picks(team_id: int, gw: int):
        if team_id == team_a:
            return {"picks": [{"element": 9901}]}
        return {"picks": [{"element": 9902}]}

    async def mock_get_entry(team_id: int):
        return {"current_event": 1}

    with (
        patch("fpl_lens.services.notifications.fpl_client.get_entry", side_effect=mock_get_entry),
        patch("fpl_lens.services.notifications.fpl_client.get_picks", side_effect=mock_get_picks),
        patch.object(
            NotificationDispatchService, "send_push_notification", return_value=True
        ) as mock_send,
    ):
        result = await dispatch_injury_alerts(
            db_session, user_ids=[user_a.id, user_b.id]
        )

        assert result["status"] == "ok"
        # Only User A should be notified (owns flagged player 9901)
        assert mock_send.call_count == 1
        call_args = mock_send.call_args[0]
        assert call_args[0] == dev_a.fcm_token
        assert call_args[1].channel_id == "injury"
        # Verification per Decision A7: player name omitted from alert body until confirmed
        assert "InjuredK" not in call_args[1].body
        assert "A player in your squad is reported doubtful or injured" in call_args[1].body
        # Deep links to /player/9901
        assert call_args[1].data["route"] == "/player/9901"
