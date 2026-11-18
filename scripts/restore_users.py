"""
Restore script for encrypted user and auth identity backups.
Backend Design §13.6 and Implementation Plan Sprint 12.
"""

import sys
from pathlib import Path

from fpl_lens.db.session import SessionLocal
from fpl_lens.services.backup import restore_backup_from_file


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python scripts/restore_users.py <path_to_backup.enc>", file=sys.stderr)
        sys.exit(1)

    backup_path = Path(sys.argv[1])
    if not backup_path.exists():
        print(f"Error: File {backup_path} does not exist", file=sys.stderr)
        sys.exit(1)

    db = SessionLocal()
    try:
        print(f"Restoring users and auth_identities from {backup_path}...")
        result = restore_backup_from_file(db, backup_path)
        print(
            f"Restore complete: {result['restored_users']} users restored, "
            f"{result['restored_identities']} identities restored."
        )
    except Exception as exc:  # noqa: BLE001
        print(f"Restore failed: {exc}", file=sys.stderr)
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    main()
