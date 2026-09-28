from typing import Generator
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import sessionmaker, Session

from app.core.config import settings

# Enforce PostgreSQL configuration check
if not (settings.DATABASE_URL.startswith("postgresql://") or settings.DATABASE_URL.startswith("postgresql+psycopg://")):
    raise RuntimeError(
        "CRITICAL ERROR: Second Brain ONLY supports PostgreSQL. SQLite and local databases are strictly forbidden."
    )

# Create SQLAlchemy 2.x Engine using modern psycopg driver
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,  # Test connections for liveness before giving to session
    echo=settings.ENVIRONMENT == "development",
)

# Reusable SessionLocal factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
    expire_on_commit=False,
)


def get_db() -> Generator[Session, None, None]:
    """
    FastAPI dependency that provides a transactional database session per request.

    Yields:
        Session: Active SQLAlchemy Session instance connected to PostgreSQL.

    Raises:
        RuntimeError: Clear, developer-friendly error if PostgreSQL is unreachable.
    """
    db = SessionLocal()
    try:
        yield db
    except OperationalError as exc:
        raise RuntimeError(
            "Failed to connect to PostgreSQL database. "
            "Please verify PostgreSQL is running and DATABASE_URL in .env is correct."
        ) from exc
    finally:
        db.close()


def check_db_connection() -> bool:
    """
    Executes a lightweight query ('SELECT 1') to verify active PostgreSQL connectivity.

    Returns:
        bool: True if connection is alive and query succeeds, False otherwise.
    """
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return True
    except Exception:
        return False
