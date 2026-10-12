import subprocess
import sys


def test_migration_roundtrip():
    """Verifies that alembic downgrade base followed by upgrade head succeeds completely."""
    # Downgrade to base
    res_down = subprocess.run(
        [sys.executable, "-m", "alembic", "downgrade", "base"],
        capture_output=True,
        text=True,
    )
    assert res_down.returncode == 0, f"Alembic downgrade failed: {res_down.stderr}"

    # Upgrade to head
    res_up = subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        capture_output=True,
        text=True,
    )
    assert res_up.returncode == 0, f"Alembic upgrade failed: {res_up.stderr}"
