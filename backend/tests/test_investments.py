import uuid
from datetime import date, timedelta
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.config import settings
from app.services.investment_service import calculate_investment_status, calculate_investment_progress

settings.TESTING = True
client = TestClient(app)


@pytest.fixture
def auth_header_user_a():
    return {"Authorization": f"Bearer test-token-inv-a-{uuid.uuid4()}"}


@pytest.fixture
def auth_header_user_b():
    return {"Authorization": f"Bearer test-token-inv-b-{uuid.uuid4()}"}


def test_1_create_investment_success(auth_header_user_a):
    """1. Authenticated user can create an investment."""
    payload = {
        "name": "HDFC Fixed Deposit",
        "type": "FD",
        "monthly_contribution": "5000.00",
        "total_paid": "50000.00",
        "total_installments": 12,
        "installments_paid": 10,
        "start_date": "2026-01-01",
        "next_due_date": "2026-11-01",
        "maturity_date": "2027-01-01",
        "notes": "Emergency FD fund",
    }
    res = client.post("/api/v1/investments", json=payload, headers=auth_header_user_a)
    assert res.status_code == 201
    data = res.json()
    assert data["name"] == "HDFC Fixed Deposit"
    assert data["type"] == "FD"
    assert data["monthly_contribution"] == "5000.00"
    assert data["total_paid"] == "50000.00"
    assert data["total_installments"] == 12
    assert data["installments_paid"] == 10
    assert data["progress_percentage"] == 83.33
    assert data["status"] in ["On Track", "Due Soon", "Overdue", "Completed"]
    assert "id" in data


def test_2_list_own_investments(auth_header_user_a):
    """2. Authenticated user can list own investments."""
    client.post(
        "/api/v1/investments",
        json={
            "name": "Gold Saving Scheme 1",
            "type": "Gold Saving Schemes",
            "monthly_contribution": "2000.00",
            "total_paid": "6000.00",
            "total_installments": 11,
            "installments_paid": 3,
        },
        headers=auth_header_user_a,
    )
    res = client.get("/api/v1/investments", headers=auth_header_user_a)
    assert res.status_code == 200
    data = res.json()
    assert isinstance(data, list)
    assert len(data) >= 1


def test_3_retrieve_own_investment(auth_header_user_a):
    """3. Authenticated user can retrieve own investment by ID."""
    create_res = client.post(
        "/api/v1/investments",
        json={
            "name": "LIC Tech Term Insurance",
            "type": "Insurance",
            "monthly_contribution": "1500.00",
            "total_paid": "18000.00",
            "total_installments": 20,
            "installments_paid": 12,
        },
        headers=auth_header_user_a,
    )
    inv_id = create_res.json()["id"]

    res = client.get(f"/api/v1/investments/{inv_id}", headers=auth_header_user_a)
    assert res.status_code == 200
    assert res.json()["id"] == inv_id
    assert res.json()["name"] == "LIC Tech Term Insurance"


def test_4_update_own_investment(auth_header_user_a):
    """4. Authenticated user can update own investment."""
    create_res = client.post(
        "/api/v1/investments",
        json={
            "name": "Chit Fund Alpha",
            "type": "Chit Funds/Kuri",
            "monthly_contribution": "10000.00",
            "total_paid": "20000.00",
            "total_installments": 20,
            "installments_paid": 2,
        },
        headers=auth_header_user_a,
    )
    inv_id = create_res.json()["id"]

    update_payload = {
        "installments_paid": 3,
        "total_paid": "30000.00",
    }
    res = client.patch(f"/api/v1/investments/{inv_id}", json=update_payload, headers=auth_header_user_a)
    assert res.status_code == 200
    data = res.json()
    assert data["installments_paid"] == 3
    assert data["total_paid"] == "30000.00"
    assert data["progress_percentage"] == 15.0


def test_5_delete_own_investment(auth_header_user_a):
    """5. Authenticated user can delete own investment."""
    create_res = client.post(
        "/api/v1/investments",
        json={
            "name": "Temporary RD",
            "type": "RD",
            "monthly_contribution": "1000.00",
            "total_paid": "1000.00",
            "total_installments": 12,
            "installments_paid": 1,
        },
        headers=auth_header_user_a,
    )
    inv_id = create_res.json()["id"]

    delete_res = client.delete(f"/api/v1/investments/{inv_id}", headers=auth_header_user_a)
    assert delete_res.status_code == 204

    # Verify 404
    get_res = client.get(f"/api/v1/investments/{inv_id}", headers=auth_header_user_a)
    assert get_res.status_code == 404


def test_6_unauthenticated_request_rejected():
    """6. Unauthenticated request is rejected with 401."""
    res = client.get("/api/v1/investments")
    assert res.status_code == 401


def test_7_user_a_cannot_access_user_b_investment(auth_header_user_a, auth_header_user_b):
    """7. User A cannot access User B's investment (404 Not Found)."""
    b_res = client.post(
        "/api/v1/investments",
        json={
            "name": "User B Secret Investment",
            "type": "Gold & Jewellery",
            "monthly_contribution": "5000.00",
            "total_paid": "50000.00",
            "total_installments": 10,
            "installments_paid": 10,
        },
        headers=auth_header_user_b,
    )
    inv_b_id = b_res.json()["id"]

    a_res = client.get(f"/api/v1/investments/{inv_b_id}", headers=auth_header_user_a)
    assert a_res.status_code == 404
    assert a_res.json()["detail"] == "Investment not found."


def test_8_user_a_cannot_update_user_b_investment(auth_header_user_a, auth_header_user_b):
    """8. User A cannot update User B's investment (404 Not Found)."""
    b_res = client.post(
        "/api/v1/investments",
        json={
            "name": "User B Fund",
            "type": "FD",
            "monthly_contribution": "1000.00",
            "total_paid": "1000.00",
            "total_installments": 12,
            "installments_paid": 1,
        },
        headers=auth_header_user_b,
    )
    inv_b_id = b_res.json()["id"]

    a_patch_res = client.patch(
        f"/api/v1/investments/{inv_b_id}",
        json={"name": "Hacked Name"},
        headers=auth_header_user_a,
    )
    assert a_patch_res.status_code == 404


def test_9_user_a_cannot_delete_user_b_investment(auth_header_user_a, auth_header_user_b):
    """9. User A cannot delete User B's investment (404 Not Found)."""
    b_res = client.post(
        "/api/v1/investments",
        json={
            "name": "User B Protected",
            "type": "Insurance",
            "monthly_contribution": "2000.00",
            "total_paid": "4000.00",
            "total_installments": 12,
            "installments_paid": 2,
        },
        headers=auth_header_user_b,
    )
    inv_b_id = b_res.json()["id"]

    a_del_res = client.delete(f"/api/v1/investments/{inv_b_id}", headers=auth_header_user_a)
    assert a_del_res.status_code == 404


def test_10_invalid_category_rejected(auth_header_user_a):
    """10. Invalid investment type/category is rejected with 422 or 400."""
    res = client.post(
        "/api/v1/investments",
        json={
            "name": "Crypto Scheme",
            "type": "Cryptocurrency Nonexistent Category",
            "monthly_contribution": "100.00",
            "total_paid": "100.00",
            "total_installments": 12,
            "installments_paid": 1,
        },
        headers=auth_header_user_a,
    )
    assert res.status_code in [400, 422]
    assert "Invalid investment type" in res.text


def test_11_negative_monetary_value_rejected(auth_header_user_a):
    """11. Negative monetary value is rejected."""
    res = client.post(
        "/api/v1/investments",
        json={
            "name": "Negative Fund",
            "type": "FD",
            "monthly_contribution": "-500.00",
            "total_paid": "1000.00",
            "total_installments": 12,
            "installments_paid": 1,
        },
        headers=auth_header_user_a,
    )
    assert res.status_code in [400, 422]


def test_12_installments_paid_exceeds_total_rejected(auth_header_user_a):
    """12. installments_paid cannot exceed total_installments when total_installments > 0."""
    res = client.post(
        "/api/v1/investments",
        json={
            "name": "Invalid Installments",
            "type": "RD",
            "monthly_contribution": "1000.00",
            "total_paid": "15000.00",
            "total_installments": 12,
            "installments_paid": 15,
        },
        headers=auth_header_user_a,
    )
    assert res.status_code in [400, 422]
    assert "cannot exceed total_installments" in res.text


def test_13_progress_calculation_is_correct():
    """13. Progress percentage calculation is deterministic."""
    assert calculate_investment_progress(6, 12) == 50.0
    assert calculate_investment_progress(12, 12) == 100.0
    assert calculate_investment_progress(0, 12) == 0.0
    assert calculate_investment_progress(1, 3) == 33.33
    assert calculate_investment_progress(0, 0) == 0.0


def test_14_completed_status_derived_correctly():
    """14. Completed status is derived correctly when installments_paid >= total_installments."""
    today = date.today()
    status = calculate_investment_status(
        installments_paid=12,
        total_installments=12,
        next_due=today + timedelta(days=10),
        today=today,
    )
    assert status == "Completed"


def test_15_overdue_status_derived_correctly():
    """15. Overdue status is derived correctly when next_due < today."""
    today = date.today()
    yesterday = today - timedelta(days=1)
    status = calculate_investment_status(
        installments_paid=5,
        total_installments=12,
        next_due=yesterday,
        today=today,
    )
    assert status == "Overdue"


def test_16_due_soon_status_derived_correctly():
    """16. Due Soon status is derived correctly when next_due is within 5 days."""
    today = date.today()
    in_3_days = today + timedelta(days=3)
    status = calculate_investment_status(
        installments_paid=5,
        total_installments=12,
        next_due=in_3_days,
        today=today,
    )
    assert status == "Due Soon"


def test_17_on_track_status_derived_correctly():
    """17. On Track status is derived correctly when next_due is far in the future."""
    today = date.today()
    in_20_days = today + timedelta(days=20)
    status = calculate_investment_status(
        installments_paid=5,
        total_installments=12,
        next_due=in_20_days,
        today=today,
    )
    assert status == "On Track"


def test_18_updating_due_date_recalculates_status(auth_header_user_a):
    """18. Updating due date recalculates status dynamically."""
    today = date.today()
    in_20_days = (today + timedelta(days=20)).isoformat()
    yesterday = (today - timedelta(days=1)).isoformat()

    create_res = client.post(
        "/api/v1/investments",
        json={
            "name": "Dynamic Due Investment",
            "type": "FD",
            "monthly_contribution": "1000.00",
            "total_paid": "5000.00",
            "total_installments": 12,
            "installments_paid": 5,
            "next_due_date": in_20_days,
        },
        headers=auth_header_user_a,
    )
    inv_id = create_res.json()["id"]
    assert create_res.json()["status"] == "On Track"

    patch_res = client.patch(
        f"/api/v1/investments/{inv_id}",
        json={"next_due_date": yesterday},
        headers=auth_header_user_a,
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["status"] == "Overdue"


def test_19_updating_installments_recalculates_progress(auth_header_user_a):
    """19. Updating installments recalculates progress percentage & status."""
    create_res = client.post(
        "/api/v1/investments",
        json={
            "name": "Progress Investment",
            "type": "RD",
            "monthly_contribution": "2000.00",
            "total_paid": "4000.00",
            "total_installments": 10,
            "installments_paid": 2,
        },
        headers=auth_header_user_a,
    )
    inv_id = create_res.json()["id"]
    assert create_res.json()["progress_percentage"] == 20.0
    assert create_res.json()["status"] != "Completed"

    patch_res = client.patch(
        f"/api/v1/investments/{inv_id}",
        json={"installments_paid": 10},
        headers=auth_header_user_a,
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["progress_percentage"] == 100.0
    assert patch_res.json()["status"] == "Completed"


def test_20_summary_calculations_are_correct():
    """20. Portfolio summary calculates total invested, monthly contributions, and count breakdowns accurately."""
    auth_summary_user = {"Authorization": f"Bearer test-token-user-inv-sum-{uuid.uuid4()}"}

    today = date.today()
    yesterday = (today - timedelta(days=1)).isoformat()
    in_2_days = (today + timedelta(days=2)).isoformat()

    # Completed
    client.post(
        "/api/v1/investments",
        json={
            "name": "Inv 1 Completed",
            "type": "FD",
            "monthly_contribution": "1000.00",
            "total_paid": "12000.00",
            "total_installments": 12,
            "installments_paid": 12,
        },
        headers=auth_summary_user,
    )

    # Overdue
    client.post(
        "/api/v1/investments",
        json={
            "name": "Inv 2 Overdue",
            "type": "RD",
            "monthly_contribution": "2000.00",
            "total_paid": "4000.00",
            "total_installments": 12,
            "installments_paid": 2,
            "next_due_date": yesterday,
        },
        headers=auth_summary_user,
    )

    # Due Soon
    client.post(
        "/api/v1/investments",
        json={
            "name": "Inv 3 Due Soon",
            "type": "Gold Saving Schemes",
            "monthly_contribution": "3000.00",
            "total_paid": "6000.00",
            "total_installments": 12,
            "installments_paid": 2,
            "next_due_date": in_2_days,
        },
        headers=auth_summary_user,
    )

    res = client.get("/api/v1/investments/summary", headers=auth_summary_user)
    assert res.status_code == 200
    sum_data = res.json()
    assert sum_data["total_invested"] == "22000.00"
    assert sum_data["total_monthly_contribution"] == "6000.00"
    assert sum_data["completed_count"] == 1
    assert sum_data["active_count"] == 2
    assert sum_data["overdue_count"] == 1
    assert sum_data["due_soon_count"] == 1


def test_21_decimal_values_remain_accurate(auth_header_user_a):
    """21. Monetary values preserve exact Decimal precision (e.g. 9876543.21)."""
    payload = {
        "name": "High Value Portfolio Fund",
        "type": "FD",
        "monthly_contribution": "123456.78",
        "total_paid": "9876543.21",
        "total_installments": 100,
        "installments_paid": 80,
    }
    res = client.post("/api/v1/investments", json=payload, headers=auth_header_user_a)
    assert res.status_code == 201
    inv_id = res.json()["id"]

    get_res = client.get(f"/api/v1/investments/{inv_id}", headers=auth_header_user_a)
    assert get_res.status_code == 200
    assert get_res.json()["monthly_contribution"] == "123456.78"
    assert get_res.json()["total_paid"] == "9876543.21"
