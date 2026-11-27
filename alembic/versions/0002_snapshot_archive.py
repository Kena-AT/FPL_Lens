"""snapshot_archive

Revision ID: 0002_snapshot_archive
Revises: 0001_initial_schema
Create Date: 2026-11-27 11:58:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0002_snapshot_archive"
down_revision: str | None = "0001_initial_schema"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "snapshot_blobs",
        sa.Column("content_hash", sa.String(length=64), primary_key=True),
        sa.Column("source", sa.String(length=32), nullable=False),
        sa.Column("payload_gzip", sa.LargeBinary(), nullable=False),
        sa.Column("raw_bytes", sa.Integer(), nullable=False),
        sa.Column("compressed_bytes", sa.Integer(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )

    op.create_table(
        "snapshot_records",
        sa.Column("id", sa.BigInteger(), primary_key=True, autoincrement=True),
        sa.Column("source", sa.String(length=32), nullable=False),
        sa.Column("fetched_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("http_status", sa.Integer(), nullable=False),
        sa.Column(
            "content_hash",
            sa.String(length=64),
            sa.ForeignKey("snapshot_blobs.content_hash", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("trigger_reason", sa.String(length=32), nullable=False),
        sa.Column("gameweek", sa.Integer(), nullable=True),
        sa.Column("is_duplicate", sa.Boolean(), nullable=False, server_default=sa.text("false")),
    )
    op.create_index(
        "idx_snapshot_source_fetched",
        "snapshot_records",
        ["source", sa.text("fetched_at DESC")],
    )
    op.create_index("idx_snapshot_gw", "snapshot_records", ["gameweek"])


def downgrade() -> None:
    op.drop_index("idx_snapshot_gw", table_name="snapshot_records")
    op.drop_index("idx_snapshot_source_fetched", table_name="snapshot_records")
    op.drop_table("snapshot_records")
    op.drop_table("snapshot_blobs")
