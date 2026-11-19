import uuid

import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from fpl_lens.db.models import ModelVersion, User


def test_unique_fpl_team_id_constraint(db_session: Session):
    """Verifies that inserting two users with the same fpl_team_id raises an IntegrityError."""
    suffix = uuid.uuid4().hex[:8]
    team_id = int(str(uuid.uuid4().int)[:8])
    user1 = User(
        id=uuid.uuid4(),
        email=f"user1_test_{suffix}@example.com",
        fpl_team_id=team_id,
        status="active",
    )
    try:
        db_session.add(user1)
        db_session.commit()

        user2 = User(
            id=uuid.uuid4(),
            email=f"user2_test_{suffix}@example.com",
            fpl_team_id=team_id,
            status="active",
        )
        db_session.add(user2)

        with pytest.raises(IntegrityError):
            db_session.commit()

        db_session.rollback()
    finally:
        db_session.query(User).filter(User.id == user1.id).delete()
        db_session.commit()


def test_single_active_model_version_constraint(db_session: Session):
    """Verifies that inserting a second active model version violates the partial unique index."""
    suffix = uuid.uuid4().hex[:8]
    v1 = ModelVersion(
        version=f"xp-test-{suffix}-1",
        config={"window": 5},
        status="active",
        notes="First active model",
    )
    try:
        db_session.add(v1)
        db_session.commit()

        v2 = ModelVersion(
            version=f"xp-test-{suffix}-2",
            config={"window": 10},
            status="active",
            notes="Second active model should fail",
        )
        db_session.add(v2)

        with pytest.raises(IntegrityError):
            db_session.commit()

        db_session.rollback()
    finally:
        db_session.query(ModelVersion).filter(ModelVersion.version == v1.version).delete()
        db_session.commit()
