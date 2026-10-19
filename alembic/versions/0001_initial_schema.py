"""initial_schema

Revision ID: 0001_initial_schema
Revises:
Create Date: 2026-10-12 14:35:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0001_initial_schema"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # 0. Extensions
    op.execute("CREATE EXTENSION IF NOT EXISTS citext;")
    op.execute('CREATE EXTENSION IF NOT EXISTS "pgcrypto";')

    # 1. Enums
    player_position_enum = postgresql.ENUM("GK", "DEF", "MID", "FWD", name="player_position")
    player_position_enum.create(op.get_bind(), checkfirst=True)

    # 2. users
    op.create_table(
        "users",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("email", postgresql.CITEXT(), unique=True, nullable=True),
        sa.Column("email_verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("password_hash", sa.Text(), nullable=True),
        sa.Column("display_name", sa.String(length=64), nullable=True),
        sa.Column("fpl_team_id", sa.Integer(), nullable=False, unique=True),
        sa.Column("status", sa.String(length=16), nullable=False, server_default="active"),
        sa.Column("failed_login_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("locked_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("deletion_requested_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
    )

    # 3. auth_identities
    op.create_table(
        "auth_identities",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("provider", sa.String(length=16), nullable=False),
        sa.Column("provider_subject", sa.String(length=255), nullable=False),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
        sa.UniqueConstraint("provider", "provider_subject", name="uq_identity"),
    )

    # 4. email_codes
    op.create_table(
        "email_codes",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("purpose", sa.String(length=16), nullable=False),
        sa.Column("code_hash", sa.LargeBinary(), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
    )
    op.create_index("idx_email_codes_user", "email_codes", ["user_id", sa.text("created_at DESC")])

    # 5. refresh_tokens
    op.create_table(
        "refresh_tokens",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("family_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("token_hash", sa.LargeBinary(), nullable=False, unique=True),
        sa.Column(
            "issued_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "replaced_by",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("refresh_tokens.id"),
            nullable=True,
        ),
    )
    op.create_index("idx_refresh_family", "refresh_tokens", ["family_id"])

    # 6. devices
    op.create_table(
        "devices",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("fcm_token", sa.Text(), nullable=False, unique=True),
        sa.Column("platform", sa.String(length=16), nullable=False, server_default="android"),
        sa.Column(
            "last_seen_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
    )
    op.create_index("idx_devices_user", "devices", ["user_id"])

    # 7. notification_preferences
    op.create_table(
        "notification_preferences",
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column(
            "deadline_reminders", sa.Boolean(), nullable=False, server_default=sa.text("true")
        ),
        sa.Column("injury_alerts", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("deadline_reminder_hours", sa.Integer(), nullable=False, server_default="6"),
        sa.CheckConstraint(
            "deadline_reminder_hours IN (1, 3, 6, 12, 24)", name="ck_deadline_reminder_hours"
        ),
    )

    # 8. teams
    op.create_table(
        "teams",
        sa.Column("fpl_id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=64), nullable=False),
        sa.Column("short_name", sa.String(length=3), nullable=False),
        sa.Column("strength_attack_home", sa.Integer(), nullable=False),
        sa.Column("strength_attack_away", sa.Integer(), nullable=False),
        sa.Column("strength_defence_home", sa.Integer(), nullable=False),
        sa.Column("strength_defence_away", sa.Integer(), nullable=False),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
    )

    # 9. players
    op.create_table(
        "players",
        sa.Column("fpl_id", sa.Integer(), primary_key=True),
        sa.Column("first_name", sa.String(length=64), nullable=False),
        sa.Column("second_name", sa.String(length=64), nullable=False),
        sa.Column("web_name", sa.String(length=64), nullable=False),
        sa.Column(
            "position",
            postgresql.ENUM("GK", "DEF", "MID", "FWD", name="player_position", create_type=False),
            nullable=False,
        ),
        sa.Column("team_fpl_id", sa.Integer(), sa.ForeignKey("teams.fpl_id"), nullable=False),
        sa.Column("now_cost", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=2), nullable=False),
        sa.Column("chance_of_playing_next_round", sa.Integer(), nullable=True),
        sa.Column("news", sa.Text(), nullable=True),
        sa.Column("news_added_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expected_goals_season", sa.Numeric(precision=7, scale=3), nullable=True),
        sa.Column("expected_assists_season", sa.Numeric(precision=7, scale=3), nullable=True),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
    )
    op.create_index("idx_players_team", "players", ["team_fpl_id"])

    # 10. gameweeks
    op.create_table(
        "gameweeks",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=32), nullable=False),
        sa.Column("deadline_time", sa.DateTime(timezone=True), nullable=False),
        sa.Column("finished", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("is_current", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("is_next", sa.Boolean(), nullable=False, server_default=sa.text("false")),
    )
    op.create_index(
        "uq_gw_current",
        "gameweeks",
        ["is_current"],
        unique=True,
        postgresql_where=sa.text("is_current = true"),
    )

    # 11. fixtures
    op.create_table(
        "fixtures",
        sa.Column("fpl_id", sa.Integer(), primary_key=True),
        sa.Column("gameweek", sa.Integer(), sa.ForeignKey("gameweeks.id"), nullable=True),
        sa.Column("kickoff_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("home_team_fpl_id", sa.Integer(), sa.ForeignKey("teams.fpl_id"), nullable=False),
        sa.Column("away_team_fpl_id", sa.Integer(), sa.ForeignKey("teams.fpl_id"), nullable=False),
        sa.Column("finished", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("home_score", sa.Integer(), nullable=True),
        sa.Column("away_score", sa.Integer(), nullable=True),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
    )
    op.create_index("idx_fixtures_gw", "fixtures", ["gameweek"])

    # 12. player_fixture_stats
    op.create_table(
        "player_fixture_stats",
        sa.Column("player_fpl_id", sa.Integer(), sa.ForeignKey("players.fpl_id"), nullable=False),
        sa.Column("fixture_fpl_id", sa.Integer(), sa.ForeignKey("fixtures.fpl_id"), nullable=False),
        sa.Column("gameweek", sa.Integer(), sa.ForeignKey("gameweeks.id"), nullable=False),
        sa.Column("was_starter", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("minutes", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_points", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("goals_scored", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("assists", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("clean_sheets", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("goals_conceded", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("defensive_contributions", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("bps", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("bonus", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("yellow_cards", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("red_cards", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("source_fetched_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("player_fpl_id", "fixture_fpl_id"),
    )
    op.create_index(
        "idx_pfs_player_gw", "player_fixture_stats", ["player_fpl_id", sa.text("gameweek DESC")]
    )

    # 13. model_versions
    op.create_table(
        "model_versions",
        sa.Column("version", sa.String(length=32), primary_key=True),
        sa.Column("config", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False, server_default="shadow"),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
        sa.Column("notes", sa.Text(), nullable=True),
    )
    op.create_index(
        "uq_model_active",
        "model_versions",
        ["status"],
        unique=True,
        postgresql_where=sa.text("status = 'active'"),
    )

    # 14. projection_runs
    op.create_table(
        "projection_runs",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("gameweek", sa.Integer(), sa.ForeignKey("gameweeks.id"), nullable=False),
        sa.Column(
            "model_version",
            sa.String(length=32),
            sa.ForeignKey("model_versions.version"),
            nullable=False,
        ),
        sa.Column("input_hash", sa.LargeBinary(), nullable=False),
        sa.Column("inputs_as_of", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
        sa.UniqueConstraint(
            "gameweek", "model_version", "input_hash", name="uq_projection_run_inputs"
        ),
    )

    # 15. player_projections
    op.create_table(
        "player_projections",
        sa.Column(
            "run_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("projection_runs.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("player_fpl_id", sa.Integer(), sa.ForeignKey("players.fpl_id"), nullable=False),
        sa.Column("fixture_fpl_id", sa.Integer(), sa.ForeignKey("fixtures.fpl_id"), nullable=False),
        sa.Column("availability", sa.Numeric(precision=4, scale=3), nullable=False),
        sa.Column("p_start", sa.Numeric(precision=4, scale=3), nullable=False),
        sa.Column("p_sub", sa.Numeric(precision=4, scale=3), nullable=False),
        sa.Column("p_60_plus_given_start", sa.Numeric(precision=4, scale=3), nullable=False),
        sa.Column("expected_minutes", sa.Numeric(precision=5, scale=2), nullable=False),
        sa.Column("exp_goals", sa.Numeric(precision=6, scale=3), nullable=False),
        sa.Column("exp_assists", sa.Numeric(precision=6, scale=3), nullable=False),
        sa.Column("exp_appearance", sa.Numeric(precision=6, scale=3), nullable=False),
        sa.Column("exp_clean_sheet", sa.Numeric(precision=6, scale=3), nullable=False),
        sa.Column("exp_goals_conceded", sa.Numeric(precision=6, scale=3), nullable=False),
        sa.Column("exp_dc", sa.Numeric(precision=6, scale=3), nullable=False),
        sa.Column("exp_bonus", sa.Numeric(precision=6, scale=3), nullable=False),
        sa.Column("exp_card_penalty", sa.Numeric(precision=6, scale=3), nullable=False),
        sa.Column("expected_points", sa.Numeric(precision=6, scale=3), nullable=False),
        sa.PrimaryKeyConstraint("run_id", "player_fpl_id", "fixture_fpl_id"),
    )

    # 16. published_projections
    op.create_table(
        "published_projections",
        sa.Column("gameweek", sa.Integer(), sa.ForeignKey("gameweeks.id"), primary_key=True),
        sa.Column(
            "run_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("projection_runs.id"),
            nullable=False,
        ),
        sa.Column(
            "published_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
        sa.Column("bundle_json", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
    )

    # 17. cache_entries
    op.create_table(
        "cache_entries",
        sa.Column("cache_key", sa.Text(), primary_key=True),
        sa.Column("value", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("idx_cache_expiry", "cache_entries", ["expires_at"])

    # 18. ingestion_runs
    op.create_table(
        "ingestion_runs",
        sa.Column("id", sa.BigInteger(), primary_key=True, autoincrement=True),
        sa.Column("job_name", sa.String(length=48), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("finished_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("rows_written", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("error_summary", sa.Text(), nullable=True),
    )

    # 19. audit_events
    op.create_table(
        "audit_events",
        sa.Column("id", sa.BigInteger(), primary_key=True, autoincrement=True),
        sa.Column(
            "occurred_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
        sa.Column("actor_type", sa.String(length=16), nullable=False),
        sa.Column("actor_id", sa.String(length=64), nullable=True),
        sa.Column("action", sa.String(length=48), nullable=False),
        sa.Column("target_type", sa.String(length=32), nullable=True),
        sa.Column("target_id", sa.String(length=64), nullable=True),
        sa.Column("ip_hash", sa.LargeBinary(), nullable=True),
        sa.Column("metadata", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
    )


def downgrade() -> None:
    # Drop in exact reverse dependency order
    op.drop_table("audit_events")
    op.drop_table("ingestion_runs")
    op.drop_index("idx_cache_expiry", table_name="cache_entries")
    op.drop_table("cache_entries")
    op.drop_table("published_projections")
    op.drop_table("player_projections")
    op.drop_table("projection_runs")
    op.drop_index("uq_model_active", table_name="model_versions")
    op.drop_table("model_versions")
    op.drop_index("idx_pfs_player_gw", table_name="player_fixture_stats")
    op.drop_table("player_fixture_stats")
    op.drop_index("idx_fixtures_gw", table_name="fixtures")
    op.drop_table("fixtures")
    op.drop_index("uq_gw_current", table_name="gameweeks")
    op.drop_table("gameweeks")
    op.drop_index("idx_players_team", table_name="players")
    op.drop_table("players")
    op.drop_table("teams")
    op.drop_table("notification_preferences")
    op.drop_index("idx_devices_user", table_name="devices")
    op.drop_table("devices")
    op.drop_index("idx_refresh_family", table_name="refresh_tokens")
    op.drop_table("refresh_tokens")
    op.drop_index("idx_email_codes_user", table_name="email_codes")
    op.drop_table("email_codes")
    op.drop_table("auth_identities")
    op.drop_table("users")

    player_position_enum = postgresql.ENUM("GK", "DEF", "MID", "FWD", name="player_position")
    player_position_enum.drop(op.get_bind(), checkfirst=True)
