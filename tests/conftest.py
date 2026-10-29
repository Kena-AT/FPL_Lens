import pytestfrom fastapi.testclient import TestClientfrom sqlalchemy.orm import Sessionfrom fpl_lens.api.app import appfrom fpl_lens.db.session import SessionLocal@pytest.fixture(scope="session")
def client() -> TestClient:
    return TestClient(app)


@pytest.fixture(scope="function")
def db_session() -> Session:
    session = SessionLocal()
    try:
        yield session
    finally:
        session.rollback()
        session.close()


@pytest.fixture(scope="session", autouse=True)
def cleanup_test_gameweeks():
    session = SessionLocal()
    orig_current = []
    orig_next = []
    try:
        from fpl_lens.db.models import Gameweek

        orig_current = [
            gw.id
            for gw in session.query(Gameweek)
            .filter(Gameweek.id <= 38, Gameweek.is_current.is_(True))
            .all()
        ]
        orig_next = [
            gw.id
            for gw in session.query(Gameweek)
            .filter(Gameweek.id <= 38, Gameweek.is_next.is_(True))
            .all()
        ]
    except Exception:  # noqa: BLE001
        pass
    finally:
        session.close()

    yield

    session = SessionLocal()
    try:
        from fpl_lens.db.models import (            Fixture,            Gameweek,            PlayerFixtureStat,            ProjectionRun,            PublishedProjection,        )

        test_gw_ids = [
            gw[0]
            for gw in session.query(Gameweek.id).filter(Gameweek.id > 38).all()
        ]
        if test_gw_ids:
            session.query(PublishedProjection).filter(PublishedProjection.gameweek.in_(test_gw_ids)).delete(synchronize_session=False)
            session.query(PlayerFixtureStat).filter(PlayerFixtureStat.gameweek.in_(test_gw_ids)).delete(synchronize_session=False)
            session.query(ProjectionRun).filter(ProjectionRun.gameweek.in_(test_gw_ids)).delete(synchronize_session=False)
            session.query(Fixture).filter(Fixture.gameweek.in_(test_gw_ids)).delete(synchronize_session=False)
            session.query(Gameweek).filter(Gameweek.id.in_(test_gw_ids)).delete(synchronize_session=False)

        if orig_current:
            session.query(Gameweek).filter(Gameweek.id <= 38).update({"is_current": False})
            session.query(Gameweek).filter(Gameweek.id.in_(orig_current)).update({"is_current": True})
        if orig_next:
            session.query(Gameweek).filter(Gameweek.id <= 38).update({"is_next": False})
            session.query(Gameweek).filter(Gameweek.id.in_(orig_next)).update({"is_next": True})
        session.commit()
    except Exception:  # noqa: BLE001
        session.rollback()
    finally:
        session.close()
