import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from src.fpl_lens.api.app import app
from src.fpl_lens.db.session import SessionLocal


@pytest.fixture(scope="session")
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
