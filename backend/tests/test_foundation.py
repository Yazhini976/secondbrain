import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.config import Settings
from app.db.base import Base
from app.core.security import verify_id_token

client = TestClient(app)


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Second Brain API"}


def test_root_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_api_v1_health_endpoint():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_api_v1_health_db_endpoint():
    """Verify live PostgreSQL connectivity check endpoint."""
    response = client.get("/api/v1/health/db")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["database"] == "postgresql"
    assert data["connected"] is True


def test_sqlite_url_rejection():
    """Verify that SQLite URLs are strictly rejected by settings validation."""
    with pytest.raises(ValueError) as excinfo:
        Settings(DATABASE_URL="sqlite:///./test.db")
    assert "strictly requires PostgreSQL" in str(excinfo.value)


def test_postgres_url_validation():
    """Verify that PostgreSQL URLs pass settings validation."""
    settings = Settings(DATABASE_URL="postgresql+psycopg://user:pass@localhost:5432/second_brain")
    assert settings.DATABASE_URL.startswith("postgresql+psycopg://")


def test_verify_invalid_token():
    """Verify token verification with invalid token raises ValueError."""
    with pytest.raises(ValueError):
        verify_id_token("invalid-unrecognized-token")


def test_base_metadata():
    """Verify Declarative Base metadata is initialized."""
    assert Base.metadata is not None
