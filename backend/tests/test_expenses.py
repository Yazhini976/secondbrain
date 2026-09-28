import uuid
from datetime import date
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.config import settings

settings.TESTING = True
client = TestClient(app)


@pytest.fixture
def auth_header_user_a():
    return {"Authorization": f"Bearer test-token-user-exp-a-{uuid.uuid4()}"}


@pytest.fixture
def auth_header_user_b():
    return {"Authorization": f"Bearer test-token-user-exp-b-{uuid.uuid4()}"}


def test_1_create_expense_success(auth_header_user_a):
    """1. Authenticated user can create expense."""
    payload = {
        "merchant": "Supermarket Grocery",
        "amount": "125.50",
        "category": "Food & Dining",
        "transaction_date": "2026-09-15",
        "notes": "Weekly groceries",
    }
    res = client.post("/api/v1/expenses", json=payload, headers=auth_header_user_a)
    assert res.status_code == 201
    data = res.json()
    assert data["merchant"] == "Supermarket Grocery"
    assert data["amount"] == "125.50"
    assert data["category"] == "Food & Dining"
    assert data["transaction_date"] == "2026-09-15"
    assert data["notes"] == "Weekly groceries"
    assert "id" in data


def test_2_list_own_expenses(auth_header_user_a):
    """2. Authenticated user can list own expenses."""
    client.post(
        "/api/v1/expenses",
        json={
            "merchant": "Store",
            "amount": "50.00",
            "category": "Shopping",
            "transaction_date": "2026-09-15",
        },
        headers=auth_header_user_a,
    )
    res = client.get("/api/v1/expenses", headers=auth_header_user_a)
    assert res.status_code == 200
    data = res.json()
    assert isinstance(data, list)
    assert len(data) >= 1


def test_3_retrieve_own_expense(auth_header_user_a):
    """3. Authenticated user can retrieve own expense by ID."""
    create_res = client.post(
        "/api/v1/expenses",
        json={
            "merchant": "Bus Ticket",
            "amount": "45.00",
            "category": "Transport",
            "transaction_date": "2026-09-16",
        },
        headers=auth_header_user_a,
    )
    expense_id = create_res.json()["id"]

    res = client.get(f"/api/v1/expenses/{expense_id}", headers=auth_header_user_a)
    assert res.status_code == 200
    assert res.json()["id"] == expense_id
    assert res.json()["merchant"] == "Bus Ticket"


def test_4_update_own_expense(auth_header_user_a):
    """4. Authenticated user can update own expense."""
    create_res = client.post(
        "/api/v1/expenses",
        json={
            "merchant": "Coffee Shop",
            "amount": "12.00",
            "category": "Food & Dining",
            "transaction_date": "2026-09-17",
        },
        headers=auth_header_user_a,
    )
    expense_id = create_res.json()["id"]

    update_payload = {
        "merchant": "Specialty Coffee Shop",
        "amount": "15.75",
    }
    res = client.patch(f"/api/v1/expenses/{expense_id}", json=update_payload, headers=auth_header_user_a)
    assert res.status_code == 200
    data = res.json()
    assert data["merchant"] == "Specialty Coffee Shop"
    assert data["amount"] == "15.75"


def test_5_delete_own_expense(auth_header_user_a):
    """5. Authenticated user can delete own expense."""
    create_res = client.post(
        "/api/v1/expenses",
        json={
            "merchant": "Movie Ticket",
            "amount": "25.00",
            "category": "Other",
            "transaction_date": "2026-09-18",
        },
        headers=auth_header_user_a,
    )
    expense_id = create_res.json()["id"]

    delete_res = client.delete(f"/api/v1/expenses/{expense_id}", headers=auth_header_user_a)
    assert delete_res.status_code == 204

    # Verify 404 after deletion
    get_res = client.get(f"/api/v1/expenses/{expense_id}", headers=auth_header_user_a)
    assert get_res.status_code == 404


def test_6_unauthenticated_request_rejected():
    """6. Unauthenticated request is rejected with 401."""
    res = client.get("/api/v1/expenses")
    assert res.status_code == 401


def test_7_user_a_cannot_retrieve_user_b_expense(auth_header_user_a, auth_header_user_b):
    """7. User A cannot retrieve User B's expense (returns 404 Not Found)."""
    b_res = client.post(
        "/api/v1/expenses",
        json={
            "merchant": "User B Secret Expense",
            "amount": "999.00",
            "category": "Shopping",
            "transaction_date": "2026-09-19",
        },
        headers=auth_header_user_b,
    )
    expense_b_id = b_res.json()["id"]

    a_get_res = client.get(f"/api/v1/expenses/{expense_b_id}", headers=auth_header_user_a)
    assert a_get_res.status_code == 404
    assert a_get_res.json()["detail"] == "Expense not found"


def test_8_user_a_cannot_update_user_b_expense(auth_header_user_a, auth_header_user_b):
    """8. User A cannot update User B's expense (returns 404 Not Found)."""
    b_res = client.post(
        "/api/v1/expenses",
        json={
            "merchant": "User B Item",
            "amount": "50.00",
            "category": "Shopping",
            "transaction_date": "2026-09-19",
        },
        headers=auth_header_user_b,
    )
    expense_b_id = b_res.json()["id"]

    a_patch_res = client.patch(
        f"/api/v1/expenses/{expense_b_id}",
        json={"merchant": "Hacked Merchant"},
        headers=auth_header_user_a,
    )
    assert a_patch_res.status_code == 404


def test_9_user_a_cannot_delete_user_b_expense(auth_header_user_a, auth_header_user_b):
    """9. User A cannot delete User B's expense (returns 404 Not Found)."""
    b_res = client.post(
        "/api/v1/expenses",
        json={
            "merchant": "User B Protected",
            "amount": "80.00",
            "category": "Bills & Utilities",
            "transaction_date": "2026-09-19",
        },
        headers=auth_header_user_b,
    )
    expense_b_id = b_res.json()["id"]

    a_delete_res = client.delete(f"/api/v1/expenses/{expense_b_id}", headers=auth_header_user_a)
    assert a_delete_res.status_code == 404


def test_10_month_filtering_works(auth_header_user_a):
    """10. Month filtering works."""
    client.post(
        "/api/v1/expenses",
        json={
            "merchant": "September Expense",
            "amount": "100.00",
            "category": "Shopping",
            "transaction_date": "2026-09-10",
        },
        headers=auth_header_user_a,
    )
    client.post(
        "/api/v1/expenses",
        json={
            "merchant": "October Expense",
            "amount": "200.00",
            "category": "Shopping",
            "transaction_date": "2026-10-05",
        },
        headers=auth_header_user_a,
    )

    res_sep = client.get("/api/v1/expenses?year=2026&month=9", headers=auth_header_user_a)
    assert res_sep.status_code == 200
    sep_dates = [item["transaction_date"] for item in res_sep.json()]
    assert all(d.startswith("2026-09-") for d in sep_dates)

    res_oct = client.get("/api/v1/expenses?year=2026&month=10", headers=auth_header_user_a)
    assert res_oct.status_code == 200
    oct_dates = [item["transaction_date"] for item in res_oct.json()]
    assert all(d.startswith("2026-10-") for d in oct_dates)


def test_11_category_filtering_works(auth_header_user_a):
    """11. Category filtering works."""
    client.post(
        "/api/v1/expenses",
        json={
            "merchant": "Electric Bill",
            "amount": "150.00",
            "category": "Bills & Utilities",
            "transaction_date": "2026-09-20",
        },
        headers=auth_header_user_a,
    )
    res = client.get("/api/v1/expenses?category=Bills%20%26%20Utilities", headers=auth_header_user_a)
    assert res.status_code == 200
    items = res.json()
    assert len(items) >= 1
    assert all(item["category"] == "Bills & Utilities" for item in items)


def test_12_month_plus_category_filtering_works(auth_header_user_a):
    """12. Month + category filtering works simultaneously."""
    client.post(
        "/api/v1/expenses",
        json={
            "merchant": "Sept Food",
            "amount": "30.00",
            "category": "Food & Dining",
            "transaction_date": "2026-09-01",
        },
        headers=auth_header_user_a,
    )

    url = "/api/v1/expenses?year=2026&month=9&category=Food%20%26%20Dining"
    res = client.get(url, headers=auth_header_user_a)
    assert res.status_code == 200
    items = res.json()
    assert len(items) >= 1
    assert all(item["category"] == "Food & Dining" and item["transaction_date"].startswith("2026-09-") for item in items)


def test_13_invalid_category_rejected(auth_header_user_a):
    """13. Invalid category is rejected with 422 Unprocessable Entity."""
    payload = {
        "merchant": "Invalid Category Merchant",
        "amount": "50.00",
        "category": "Luxury Entertainment Nonexistent",
        "transaction_date": "2026-09-20",
    }
    res = client.post("/api/v1/expenses", json=payload, headers=auth_header_user_a)
    assert res.status_code == 422
    assert "Invalid expense category" in res.text


def test_14_negative_or_zero_amount_rejected(auth_header_user_a):
    """14. Negative or zero amount is rejected with 422."""
    res_zero = client.post(
        "/api/v1/expenses",
        json={
            "merchant": "Zero",
            "amount": "0.00",
            "category": "Shopping",
            "transaction_date": "2026-09-20",
        },
        headers=auth_header_user_a,
    )
    assert res_zero.status_code == 422

    res_negative = client.post(
        "/api/v1/expenses",
        json={
            "merchant": "Negative",
            "amount": "-50.00",
            "category": "Shopping",
            "transaction_date": "2026-09-20",
        },
        headers=auth_header_user_a,
    )
    assert res_negative.status_code == 422


def test_15_monthly_summary_calculates_correctly():
    """15. Monthly summary calculates total and category totals correctly for isolated user."""
    auth_summary_user = {"Authorization": f"Bearer test-token-user-summary-{uuid.uuid4()}"}

    # Add specific expenses in Nov 2026
    client.post(
        "/api/v1/expenses",
        json={
            "merchant": "Dinner",
            "amount": "500.50",
            "category": "Food & Dining",
            "transaction_date": "2026-11-05",
        },
        headers=auth_summary_user,
    )
    client.post(
        "/api/v1/expenses",
        json={
            "merchant": "Taxi",
            "amount": "200.25",
            "category": "Transport",
            "transaction_date": "2026-11-10",
        },
        headers=auth_summary_user,
    )

    res = client.get("/api/v1/expenses/summary?year=2026&month=11", headers=auth_summary_user)
    assert res.status_code == 200
    summary = res.json()
    assert summary["year"] == 2026
    assert summary["month"] == 11
    assert summary["total"] == "700.75"
    assert summary["category_totals"]["Food & Dining"] == "500.50"
    assert summary["category_totals"]["Transport"] == "200.25"
    assert summary["category_totals"]["Shopping"] == "0.00"
    assert summary["category_totals"]["Bills & Utilities"] == "0.00"
    assert summary["category_totals"]["Other"] == "0.00"


def test_16_decimal_financial_precision_preserved(auth_header_user_a):
    """16. Decimal financial precision (e.g. 1234567.89) is strictly preserved."""
    payload = {
        "merchant": "High Precision Transaction",
        "amount": "1234567.89",
        "category": "Other",
        "transaction_date": "2026-09-25",
    }
    res = client.post("/api/v1/expenses", json=payload, headers=auth_header_user_a)
    assert res.status_code == 201
    expense_id = res.json()["id"]

    get_res = client.get(f"/api/v1/expenses/{expense_id}", headers=auth_header_user_a)
    assert get_res.status_code == 200
    assert get_res.json()["amount"] == "1234567.89"
