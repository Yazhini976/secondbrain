import uuid
from datetime import datetime, timedelta, timezone
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.config import settings

settings.TESTING = True
client = TestClient(app)


@pytest.fixture
def auth_header_user_a():
    return {"Authorization": f"Bearer test-token-rem-a-{uuid.uuid4()}"}


@pytest.fixture
def auth_header_user_b():
    return {"Authorization": f"Bearer test-token-rem-b-{uuid.uuid4()}"}


def test_create_and_list_reminders(auth_header_user_a):
    payload = {
        "title": "Pay Credit Card Bill",
        "description": "Monthly HDFC card payment",
        "due_at": (datetime.now(timezone.utc) + timedelta(days=2)).isoformat(),
        "category": "Personal",
        "priority": "High",
        "is_completed": False,
    }
    res = client.post("/api/v1/reminders", json=payload, headers=auth_header_user_a)
    assert res.status_code == 201
    data = res.json()
    assert data["title"] == "Pay Credit Card Bill"
    assert data["status"] in ["Upcoming", "Due Today", "Overdue", "Completed"]

    rem_id = data["id"]
    list_res = client.get("/api/v1/reminders", headers=auth_header_user_a)
    assert list_res.status_code == 200
    items = list_res.json()
    assert any(i["id"] == rem_id for i in items)


def test_update_and_complete_reminder(auth_header_user_a):
    create_res = client.post(
        "/api/v1/reminders",
        json={
            "title": "Renew Insurance",
            "due_at": datetime.now(timezone.utc).isoformat(),
            "category": "Document",
        },
        headers=auth_header_user_a,
    )
    rem_id = create_res.json()["id"]

    patch_res = client.patch(
        f"/api/v1/reminders/{rem_id}",
        json={"is_completed": True},
        headers=auth_header_user_a,
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["is_completed"] is True
    assert patch_res.json()["status"] == "Completed"


def test_delete_reminder(auth_header_user_a):
    create_res = client.post(
        "/api/v1/reminders",
        json={
            "title": "Temp Reminder",
            "due_at": datetime.now(timezone.utc).isoformat(),
        },
        headers=auth_header_user_a,
    )
    rem_id = create_res.json()["id"]

    del_res = client.delete(f"/api/v1/reminders/{rem_id}", headers=auth_header_user_a)
    assert del_res.status_code == 204

    get_res = client.get(f"/api/v1/reminders/{rem_id}", headers=auth_header_user_a)
    assert get_res.status_code == 404


def test_user_isolation_reminders(auth_header_user_a, auth_header_user_b):
    create_res = client.post(
        "/api/v1/reminders",
        json={
            "title": "User B Secret Reminder",
            "due_at": datetime.now(timezone.utc).isoformat(),
        },
        headers=auth_header_user_b,
    )
    rem_id = create_res.json()["id"]

    get_res = client.get(f"/api/v1/reminders/{rem_id}", headers=auth_header_user_a)
    assert get_res.status_code == 404
