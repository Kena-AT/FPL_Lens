"""player_code_and_quality

Revision ID: 0003_player_code_and_quality
Revises: 0002_snapshot_archive
Create Date: 2026-11-27 14:28:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0003_player_code_and_quality"
down_revision: str | None = "0002_snapshot_archive"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("players", sa.Column("code", sa.Integer(), nullable=True))
    op.add_column(
        "players",
        sa.Column("chance_of_playing_this_round", sa.Integer(), nullable=True),
    )
    op.create_index(
        "uq_players_code",
        "players",
        ["code"],
        unique=True,
        postgresql_where=sa.text("code IS NOT NULL"),
    )


def downgrade() -> None:
    op.drop_index("uq_players_code", table_name="players")
    op.drop_column("players", "chance_of_playing_this_round")
    op.drop_column("players", "code")
