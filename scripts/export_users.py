"""
Weekly export script for `users` and `auth_identities` tables with Fernet encryption.
Backend Design §13.6 and Implementation Plan Sprint 12.
"""

import os
import sys
from datetime import UTC, datetime
from pathlib import Path

from fpl_lens.db.session import SessionLocal
from fpl_lens.services.backup import export_backup_to_file


def main() -> None:
    timestamp = datetime.now(UTC).strftime("%Y%m%d_%H%M%S")
    output_dir = Path("backups")
    output_file = output_dir / f"users_backup_{timestamp}.enc"

    db = SessionLocal()
    try:
        print(f"Starting encrypted backup of users and auth_identities to {output_file}...")
        exported_path = export_backup_to_file(db, output_file)
        size_bytes = os.path.getsize(exported_path)
        print(f"Backup successful: {exported_path} ({size_bytes} bytes).")
    except Exception as exc:  # noqa: BLE001
        print(f"Backup failed: {exc}", file=sys.stderr)
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    main()
