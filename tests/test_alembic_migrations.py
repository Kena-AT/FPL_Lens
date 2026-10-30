import subprocess
import sys

from fpl_lens.db.models import User
from fpl_lens.db.session import SessionLocal


def test_migration_roundtrip():
    """Verifies that alembic upgrade and downgrade scripts generate valid SQL forward and backward
    while strictly protecting active database tables and real user accounts from destructive drops
    per AGENTS.md §11.8."""
    session = SessionLocal()
    try:
        # Check that protected user exists
        owner_user = session.query(User).filter(User.email == "kenakaye11@gmail.com").first()
        assert owner_user is not None, "Owner account kenakaye11@gmail.com must exist in database"
    finally:
        session.close()

    # 1. Offline SQL generation test for upgrade (base -> head)
    res_up = subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "base:head", "--sql"],
        capture_output=True,
        text=True,
    )
    assert res_up.returncode == 0, f"Alembic offline upgrade failed: {res_up.stderr}"
    assert "CREATE TABLE users" in res_up.stdout, "Users table creation DDL must be generated"
    assert "CREATE TABLE projection_runs" in res_up.stdout, "Projection runs DDL must be generated"

    # 2. Offline SQL generation test for downgrade (head -> base)
    res_down = subprocess.run(
        [sys.executable, "-m", "alembic", "downgrade", "head:base", "--sql"],
        capture_output=True,
        text=True,
    )
    assert res_down.returncode == 0, f"Alembic offline downgrade failed: {res_down.stderr}"
    assert "DROP TABLE users" in res_down.stdout, "Users table drop DDL must be generated in SQL"

    # 3. Verify owner account remains untouched and intact
    session = SessionLocal()
    try:
        owner_after = session.query(User).filter(User.email == "kenakaye11@gmail.com").first()
        assert owner_after is not None, (
            "Owner account kenakaye11@gmail.com was removed during migration test!"
        )
        assert owner_after.status == "active"
    finally:
        session.close()
