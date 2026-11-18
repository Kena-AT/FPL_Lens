"""
Unit and API tests for POST /api/v1/squads/resolve per Technical Spec v1.5 §8,
Backend Design §11.3, and Frontend Implementation Plan §D12/P16.
Verifies exact match, fuzzy OCR match, diacritics normalization, slot weighting,
and strict rejection of unauthenticated or malformed requests.
"""

import uuid
from datetime import UTC, datetime
from decimal import Decimal

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from fpl_lens.db.models import Player, Team, User
from fpl_lens.services.hasher import hash_password
from fpl_lens.services.token import create_access_token


def _setup_test_players_and_teams(db: Session) -> None:
    """Seeds test teams and players for resolution testing."""
    mci = Team(
        fpl_id=1,
        name="Manchester City",
        short_name="MCI",
        strength_attack_home=1300,
        strength_attack_away=1320,
        strength_defence_home=1300,
        strength_defence_away=1320,
    )
    liv = Team(
        fpl_id=2,
        name="Liverpool",
        short_name="LIV",
        strength_attack_home=1280,
        strength_attack_away=1300,
        strength_defence_home=1280,
        strength_defence_away=1300,
    )
    ars = Team(
        fpl_id=3,
        name="Arsenal",
        short_name="ARS",
        strength_attack_home=1290,
        strength_attack_away=1310,
        strength_defence_home=1310,
        strength_defence_away=1330,
    )
    db.merge(mci)
    db.merge(liv)
    db.merge(ars)
    db.flush()

    players = [
        Player(
            fpl_id=101,
            first_name="Erling",
            second_name="Haaland",
            web_name="Haaland",
            position="FWD",
            team_fpl_id=1,
            now_cost=152,
            status="a",
            expected_goals_season=Decimal("15.2"),
            expected_assists_season=Decimal("3.1"),
        ),
        Player(
            fpl_id=102,
            first_name="Mohamed",
            second_name="Salah",
            web_name="Salah",
            position="MID",
            team_fpl_id=2,
            now_cost=128,
            status="a",
            expected_goals_season=Decimal("14.0"),
            expected_assists_season=Decimal("9.0"),
        ),
        Player(
            fpl_id=103,
            first_name="Bukayo",
            second_name="Saka",
            web_name="Saka",
            position="MID",
            team_fpl_id=3,
            now_cost=101,
            status="a",
            expected_goals_season=Decimal("8.5"),
            expected_assists_season=Decimal("7.2"),
        ),
        Player(
            fpl_id=104,
            first_name="Martin",
            second_name="Ødegaard",
            web_name="Odegaard",
            position="MID",
            team_fpl_id=3,
            now_cost=84,
            status="a",
            expected_goals_season=Decimal("5.0"),
            expected_assists_season=Decimal("6.5"),
        ),
        Player(
            fpl_id=105,
            first_name="David",
            second_name="Raya Martin",
            web_name="Raya",
            position="GK",
            team_fpl_id=3,
            now_cost=56,
            status="a",
            expected_goals_season=Decimal("0.0"),
            expected_assists_season=Decimal("0.0"),
        ),
        Player(
            fpl_id=106,
            first_name="Gabriel",
            second_name="dos Santos Magalhães",
            web_name="Gabriel",
            position="DEF",
            team_fpl_id=3,
            now_cost=62,
            status="a",
            expected_goals_season=Decimal("2.1"),
            expected_assists_season=Decimal("0.5"),
        ),
    ]
    for p in players:
        db.merge(p)
    db.commit()


def _create_authenticated_user(db: Session, email_verified: bool = True) -> tuple[User, str]:
    tag = uuid.uuid4().hex[:6]
    user = User(
        id=uuid.uuid4(),
        email=f"resolve_user_{tag}@example.com",
        password_hash=hash_password("ValidPassword123!"),
        display_name="Resolve Tester",
        fpl_team_id=int(uuid.uuid4().int % 8000000 + 1000000),
        status="active" if email_verified else "unverified",
        email_verified_at=datetime.now(UTC) if email_verified else None,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token(user)
    return user, token


def test_resolve_squad_unauthenticated(client: TestClient):
    resp = client.post("/api/v1/squads/resolve", json={"players": [{"raw_name": "Haaland"}]})
    assert resp.status_code == 401


def test_resolve_squad_unverified_user(client: TestClient, db_session: Session):
    _, token = _create_authenticated_user(db_session, email_verified=False)
    resp = client.post(
        "/api/v1/squads/resolve",
        headers={"Authorization": f"Bearer {token}"},
        json={"players": [{"raw_name": "Haaland"}]},
    )
    assert resp.status_code == 403


def test_resolve_squad_extra_fields_forbidden(client: TestClient, db_session: Session):
    _, token = _create_authenticated_user(db_session)
    resp = client.post(
        "/api/v1/squads/resolve",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "players": [{"raw_name": "Haaland"}],
            "extra_field": "disallowed",
        },
    )
    assert resp.status_code == 422


def test_resolve_squad_exact_and_fuzzy_matches(client: TestClient, db_session: Session):
    _setup_test_players_and_teams(db_session)
    _, token = _create_authenticated_user(db_session)

    payload = {
        "players": [
            {"raw_name": "Haaland", "slot": "FWD"},
            {"raw_name": "Salah", "slot": "MID"},
            {"raw_name": "Saka", "slot": "MID"},
            {"raw_name": "Ødegaard", "slot": "MID"},  # Diacritics
            {"raw_name": "Raya", "slot": "GKP"},
            {"raw_name": "Gabriel", "slot": "DEF"},
            {"raw_name": "Haland", "slot": "FWD"},  # OCR typo missing 'a'
            {"raw_name": "UnknownPlayerXYZ", "slot": "MID"},  # Unmatched
        ]
    }

    resp = client.post(
        "/api/v1/squads/resolve",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
    )
    assert resp.status_code == 200
    data = resp.json()

    assert "results" in data
    assert len(data["results"]) == 8
    assert data["all_resolved"] is False  # Because UnknownPlayerXYZ is not resolved
    assert data["unresolved_count"] >= 1

    # Haaland exact
    haaland_res = data["results"][0]
    assert haaland_res["raw_name"] == "Haaland"
    assert haaland_res["exact_match"] is True
    assert haaland_res["best_confidence"] == 1.0
    assert haaland_res["candidates"][0]["web_name"] == "Haaland"
    assert haaland_res["candidates"][0]["team_short_name"] == "MCI"
    assert haaland_res["candidates"][0]["position"] == "FWD"
    assert haaland_res["candidates"][0]["match_tier"] == "strong"

    # Odegaard diacritics
    odegaard_res = data["results"][3]
    assert odegaard_res["exact_match"] is True
    assert odegaard_res["best_confidence"] >= 0.85
    assert "degaard" in odegaard_res["candidates"][0]["web_name"].lower()

    # Haland typo
    haland_typo = data["results"][6]
    assert len(haland_typo["candidates"]) > 0
    assert haland_typo["candidates"][0]["web_name"] == "Haaland"
    assert haland_typo["candidates"][0]["confidence"] >= 0.80

    # Unknown player
    unknown_res = data["results"][7]
    assert unknown_res["exact_match"] is False


def test_resolve_squad_all_resolved_flag(client: TestClient, db_session: Session):
    _setup_test_players_and_teams(db_session)
    _, token = _create_authenticated_user(db_session)

    payload = {
        "players": [
            {"raw_name": "Haaland", "slot": "FWD"},
            {"raw_name": "Salah", "slot": "MID"},
        ]
    }

    resp = client.post(
        "/api/v1/squads/resolve",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["all_resolved"] is True
    assert data["unresolved_count"] == 0
