import uuid
import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from src.fpl_lens.db.models import ModelVersion, User


def test_unique_fpl_team_id_constraint(db_session: Session):
    """Verifies that inserting two users with the same fpl_team_id raises an IntegrityError."""
    team_id = 99999901
    user1 = User(
        id=uuid.uuid4(),
        email="user1_test@example.com",
        fpl_team_id=team_id,
        status="active",
    )
    db_session.add(user1)
    db_session.commit()

    user2 = User(
        id=uuid.uuid4(),
        email="user2_test@example.com",
        fpl_team_id=team_id,
        status="active",
    )
    db_session.add(user2)

    with pytest.raises(IntegrityError):
        db_session.commit()

    db_session.rollback()


def test_single_active_model_version_constraint(db_session: Session):
    """Verifies that inserting a second active model version violates the partial unique index."""
    v1 = ModelVersion(
        version="xp-test-1",
        config={"window": 5},
        status="active",
        notes="First active model",
    )
    db_session.add(v1)
    db_session.commit()

    v2 = ModelVersion(
        version="xp-test-2",
        config={"window": 10},
        status="active",
        notes="Second active model should fail",
    )
    db_session.add(v2)

    with pytest.raises(IntegrityError):
        db_session.commit()

    db_session.rollback()
