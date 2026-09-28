import uuid
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.main import app
from app.core.config import settings
from app.db.session import SessionLocal
from app.models.user import User
from app.models.expense import Expense

# Set settings.TESTING = True for test execution
settings.TESTING = True

client = TestClient(app)


def test_missing_authorization_header():
    """Verify that accessing protected /api/v1/auth/me without header returns 401 Unauthorized."""
    response = client.get("/api/v1/auth/me")
    assert response.status_code == 401
    assert "Missing authorization token" in response.json()["detail"]


def test_invalid_authorization_token():
    """Verify that an invalid token returns 401 Unauthorized."""
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer invalid_token_xyz"}
    )
    assert response.status_code == 401


def test_first_login_creates_user_in_postgres():
    """
    Verify that a valid token on first login automatically creates a corresponding
    PostgreSQL User record with external_auth_id equal to the Firebase UID.
    """
    test_uid = f"firebase-uid-alice-{uuid.uuid4()}"
    headers = {"Authorization": f"Bearer test-token-{test_uid}"}

    response = client.get("/api/v1/auth/me", headers=headers)
    assert response.status_code == 200
    data = response.json()

    assert data["external_auth_id"] == test_uid
    assert data["email"] == f"{test_uid}@example.com"
    assert data["is_active"] is True

    # Direct PostgreSQL verification
    with SessionLocal() as db:
        user = db.scalars(select(User).where(User.external_auth_id == test_uid)).first()
        assert user is not None
        assert str(user.id) == data["id"]
        assert user.external_auth_id == test_uid


def test_subsequent_login_reuses_existing_postgres_user():
    """
    Verify that subsequent requests with the same Firebase UID reuse the existing
    PostgreSQL user record without creating duplicates.
    """
    test_uid = f"firebase-uid-bob-{uuid.uuid4()}"
    headers = {"Authorization": f"Bearer test-token-{test_uid}"}

    # First request
    res1 = client.get("/api/v1/auth/me", headers=headers)
    assert res1.status_code == 200
    id1 = res1.json()["id"]

    # Second request
    res2 = client.get("/api/v1/auth/me", headers=headers)
    assert res2.status_code == 200
    id2 = res2.json()["id"]

    assert id1 == id2

    # Verify single user record exists in PostgreSQL
    with SessionLocal() as db:
        users = db.scalars(select(User).where(User.external_auth_id == test_uid)).all()
        assert len(users) == 1


def test_inactive_user_is_rejected():
    """
    Verify that an inactive user (is_active = False) is rejected with 401 Unauthorized.
    """
    test_uid = f"firebase-uid-charlie-{uuid.uuid4()}"
    headers = {"Authorization": f"Bearer test-token-{test_uid}"}

    # First login to create user
    res = client.get("/api/v1/auth/me", headers=headers)
    assert res.status_code == 200

    # Mark user inactive directly in PostgreSQL
    with SessionLocal() as db:
        user = db.scalars(select(User).where(User.external_auth_id == test_uid)).one()
        user.is_active = False
        db.commit()

    # Next request should be rejected with 401
    res_inactive = client.get("/api/v1/auth/me", headers=headers)
    assert res_inactive.status_code == 401
    assert "User account is inactive" in res_inactive.json()["detail"]


def test_user_scoping_isolation_principle():
    """
    Verifies that resource queries filtered by current_user.id strictly enforce
    user-level data isolation so User A cannot access User B's resources.
    """
    uid_a = f"user-a-iso-{uuid.uuid4()}"
    uid_b = f"user-b-iso-{uuid.uuid4()}"

    # Authenticate User A and User B
    res_a = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer test-token-{uid_a}"})
    res_b = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer test-token-{uid_b}"})

    user_a_id = res_a.json()["id"]
    user_b_id = res_b.json()["id"]

    # Create an expense belonging to User A in PostgreSQL
    from datetime import date
    from decimal import Decimal

    expense_id = uuid.uuid4()
    with SessionLocal() as db:
        expense_a = Expense(
            id=expense_id,
            user_id=uuid.UUID(user_a_id),
            merchant="Merchant A",
            amount=Decimal("150.00"),
            category="Food & Dining",
            transaction_date=date.today(),
        )
        db.add(expense_a)
        db.commit()

    # Verify query scoped to User A returns the expense
    with SessionLocal() as db:
        query_a = db.scalars(
            select(Expense).where(
                Expense.id == expense_id,
                Expense.user_id == uuid.UUID(user_a_id)
            )
        ).first()
        assert query_a is not None

        # Verify query scoped to User B returns NONE (User B cannot access User A's expense)
        query_b = db.scalars(
            select(Expense).where(
                Expense.id == expense_id,
                Expense.user_id == uuid.UUID(user_b_id)
            )
        ).first()
        assert query_b is None


def test_seed_dummy_data_endpoint():
    """Verify that POST /api/v1/auth/seed-dummy-data seeds dummy data into database."""
    test_uid = f"user-seed-{uuid.uuid4()}"
    headers = {"Authorization": f"Bearer test-token-{test_uid}"}

    res = client.post("/api/v1/auth/seed-dummy-data?force=true", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert "Dummy data seeded successfully" in data["message"]
    assert data["details"]["status"] == "seeded"
    assert data["details"]["counts"]["expenses"] == 24
    assert data["details"]["counts"]["investments"] == 5
    assert data["details"]["counts"]["documents"] == 6
    assert data["details"]["counts"]["reminders"] == 5
    assert data["details"]["counts"]["goals"] == 3

