from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, declarative_base, sessionmaker

from src.fpl_lens.config import settings

# Create engine using effective database URL (pooled endpoint by default)
db_url = settings.get_effective_database_url(pooled=True)

engine = create_engine(
    db_url,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
    connect_args={"connect_timeout": 10},
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    """Dependency that yields an active database session and ensures closure."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
