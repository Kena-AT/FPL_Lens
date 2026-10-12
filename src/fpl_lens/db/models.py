import uuid
from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    Column,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    LargeBinary,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.sql import func
from src.fpl_lens.db.session import Base

# Player position enum
PlayerPositionEnum = Enum("GK", "DEF", "MID", "FWD", name="player_position")


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=True)
    email_verified_at = Column(DateTime(timezone=True), nullable=True)
    password_hash = Column(Text, nullable=True)
    display_name = Column(String(64), nullable=True)
    fpl_team_id = Column(Integer, nullable=False, unique=True)
    status = Column(String(16), nullable=False, default="active")
    failed_login_count = Column(Integer, nullable=False, default=0)
    locked_until = Column(DateTime(timezone=True), nullable=True)
    deletion_requested_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())


class AuthIdentity(Base):
    __tablename__ = "auth_identities"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    provider = Column(String(16), nullable=False)  # 'email' | 'google'
    provider_subject = Column(String(255), nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    __table_args__ = (
        UniqueConstraint("provider", "provider_subject", name="uq_identity"),
    )


class EmailCode(Base):
    __tablename__ = "email_codes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    purpose = Column(String(16), nullable=False)  # 'verify_email'
    code_hash = Column(LargeBinary, nullable=False)
    attempts = Column(Integer, nullable=False, default=0)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    used_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    __table_args__ = (
        Index("idx_email_codes_user", "user_id", text("created_at DESC")),
    )


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    family_id = Column(UUID(as_uuid=True), nullable=False)
    token_hash = Column(LargeBinary, nullable=False, unique=True)
    issued_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=False)
    revoked_at = Column(DateTime(timezone=True), nullable=True)
    replaced_by = Column(UUID(as_uuid=True), ForeignKey("refresh_tokens.id"), nullable=True)

    __table_args__ = (
        Index("idx_refresh_family", "family_id"),
    )


class Device(Base):
    __tablename__ = "devices"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    fcm_token = Column(Text, nullable=False, unique=True)
    platform = Column(String(16), nullable=False, default="android")
    last_seen_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    __table_args__ = (
        Index("idx_devices_user", "user_id"),
    )


class NotificationPreference(Base):
    __tablename__ = "notification_preferences"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    deadline_reminders = Column(Boolean, nullable=False, default=True)
    injury_alerts = Column(Boolean, nullable=False, default=True)
    deadline_reminder_hours = Column(Integer, nullable=False, default=6)

    __table_args__ = (
        CheckConstraint(
            "deadline_reminder_hours IN (1, 3, 6, 12, 24)",
            name="ck_deadline_reminder_hours",
        ),
    )


class Team(Base):
    __tablename__ = "teams"

    fpl_id = Column(Integer, primary_key=True)
    name = Column(String(64), nullable=False)
    short_name = Column(String(3), nullable=False)
    strength_attack_home = Column(Integer, nullable=False)
    strength_attack_away = Column(Integer, nullable=False)
    strength_defence_home = Column(Integer, nullable=False)
    strength_defence_away = Column(Integer, nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())


class Player(Base):
    __tablename__ = "players"

    fpl_id = Column(Integer, primary_key=True)
    first_name = Column(String(64), nullable=False)
    second_name = Column(String(64), nullable=False)
    web_name = Column(String(64), nullable=False)
    position = Column(PlayerPositionEnum, nullable=False)
    team_fpl_id = Column(Integer, ForeignKey("teams.fpl_id"), nullable=False)
    now_cost = Column(Integer, nullable=False)  # tenths of £m
    status = Column(String(2), nullable=False)
    chance_of_playing_next_round = Column(Integer, nullable=True)
    news = Column(Text, nullable=True)
    news_added_at = Column(DateTime(timezone=True), nullable=True)
    expected_goals_season = Column(Numeric(7, 3), nullable=True)
    expected_assists_season = Column(Numeric(7, 3), nullable=True)
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        Index("idx_players_team", "team_fpl_id"),
    )


class Gameweek(Base):
    __tablename__ = "gameweeks"

    id = Column(Integer, primary_key=True)  # FPL event id
    name = Column(String(32), nullable=False)
    deadline_time = Column(DateTime(timezone=True), nullable=False)
    finished = Column(Boolean, nullable=False, default=False)
    is_current = Column(Boolean, nullable=False, default=False)
    is_next = Column(Boolean, nullable=False, default=False)

    __table_args__ = (
        Index("uq_gw_current", "is_current", unique=True, postgresql_where=text("is_current = true")),
    )


class Fixture(Base):
    __tablename__ = "fixtures"

    fpl_id = Column(Integer, primary_key=True)
    gameweek = Column(Integer, ForeignKey("gameweeks.id"), nullable=True)
    kickoff_time = Column(DateTime(timezone=True), nullable=True)
    home_team_fpl_id = Column(Integer, ForeignKey("teams.fpl_id"), nullable=False)
    away_team_fpl_id = Column(Integer, ForeignKey("teams.fpl_id"), nullable=False)
    finished = Column(Boolean, nullable=False, default=False)
    home_score = Column(Integer, nullable=True)
    away_score = Column(Integer, nullable=True)
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        Index("idx_fixtures_gw", "gameweek"),
    )


class PlayerFixtureStat(Base):
    __tablename__ = "player_fixture_stats"

    player_fpl_id = Column(Integer, ForeignKey("players.fpl_id"), primary_key=True)
    fixture_fpl_id = Column(Integer, ForeignKey("fixtures.fpl_id"), primary_key=True)
    gameweek = Column(Integer, ForeignKey("gameweeks.id"), nullable=False)
    was_starter = Column(Boolean, nullable=False, default=False)
    minutes = Column(Integer, nullable=False, default=0)
    total_points = Column(Integer, nullable=False, default=0)
    goals_scored = Column(Integer, nullable=False, default=0)
    assists = Column(Integer, nullable=False, default=0)
    clean_sheets = Column(Integer, nullable=False, default=0)
    goals_conceded = Column(Integer, nullable=False, default=0)
    defensive_contributions = Column(Integer, nullable=False, default=0)
    bps = Column(Integer, nullable=False, default=0)
    bonus = Column(Integer, nullable=False, default=0)
    yellow_cards = Column(Integer, nullable=False, default=0)
    red_cards = Column(Integer, nullable=False, default=0)
    source_fetched_at = Column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        Index("idx_pfs_player_gw", "player_fpl_id", text("gameweek DESC")),
    )


class ModelVersion(Base):
    __tablename__ = "model_versions"

    version = Column(String(32), primary_key=True)
    config = Column(JSONB, nullable=False)
    status = Column(String(16), nullable=False, default="shadow")  # shadow | active | retired
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    notes = Column(Text, nullable=True)

    __table_args__ = (
        Index("uq_model_active", "status", unique=True, postgresql_where=text("status = 'active'")),
    )


class ProjectionRun(Base):
    __tablename__ = "projection_runs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    gameweek = Column(Integer, ForeignKey("gameweeks.id"), nullable=False)
    model_version = Column(String(32), ForeignKey("model_versions.version"), nullable=False)
    input_hash = Column(LargeBinary, nullable=False)
    inputs_as_of = Column(DateTime(timezone=True), nullable=False)
    status = Column(String(16), nullable=False)  # OK | PARTIAL | FAILED
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    __table_args__ = (
        UniqueConstraint("gameweek", "model_version", "input_hash", name="uq_projection_run_inputs"),
    )


class PlayerProjection(Base):
    __tablename__ = "player_projections"

    run_id = Column(UUID(as_uuid=True), ForeignKey("projection_runs.id", ondelete="CASCADE"), primary_key=True)
    player_fpl_id = Column(Integer, ForeignKey("players.fpl_id"), primary_key=True)
    fixture_fpl_id = Column(Integer, ForeignKey("fixtures.fpl_id"), primary_key=True)
    availability = Column(Numeric(4, 3), nullable=False)
    p_start = Column(Numeric(4, 3), nullable=False)
    p_sub = Column(Numeric(4, 3), nullable=False)
    p_60_plus_given_start = Column(Numeric(4, 3), nullable=False)
    expected_minutes = Column(Numeric(5, 2), nullable=False)
    exp_goals = Column(Numeric(6, 3), nullable=False)
    exp_assists = Column(Numeric(6, 3), nullable=False)
    exp_appearance = Column(Numeric(6, 3), nullable=False)
    exp_clean_sheet = Column(Numeric(6, 3), nullable=False)
    exp_goals_conceded = Column(Numeric(6, 3), nullable=False)
    exp_dc = Column(Numeric(6, 3), nullable=False)
    exp_bonus = Column(Numeric(6, 3), nullable=False)
    exp_card_penalty = Column(Numeric(6, 3), nullable=False)
    expected_points = Column(Numeric(6, 3), nullable=False)


class PublishedProjection(Base):
    __tablename__ = "published_projections"

    gameweek = Column(Integer, ForeignKey("gameweeks.id"), primary_key=True)
    run_id = Column(UUID(as_uuid=True), ForeignKey("projection_runs.id"), nullable=False)
    published_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    bundle_json = Column(JSONB, nullable=False)


class CacheEntry(Base):
    __tablename__ = "cache_entries"

    cache_key = Column(Text, primary_key=True)
    value = Column(JSONB, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        Index("idx_cache_expiry", "expires_at"),
    )


class IngestionRun(Base):
    __tablename__ = "ingestion_runs"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    job_name = Column(String(48), nullable=False)
    started_at = Column(DateTime(timezone=True), nullable=False)
    finished_at = Column(DateTime(timezone=True), nullable=True)
    status = Column(String(16), nullable=False)  # RUNNING | OK | PARTIAL | FAILED
    rows_written = Column(Integer, nullable=False, default=0)
    error_summary = Column(Text, nullable=True)


class AuditEvent(Base):
    __tablename__ = "audit_events"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    occurred_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    actor_type = Column(String(16), nullable=False)
    actor_id = Column(String(64), nullable=True)
    action = Column(String(48), nullable=False)
    target_type = Column(String(32), nullable=True)
    target_id = Column(String(64), nullable=True)
    ip_hash = Column(LargeBinary, nullable=True)
    audit_metadata = Column("metadata", JSONB, nullable=True)
