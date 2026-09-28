import uuid
from datetime import date, timedelta
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.config import settings

settings.TESTING = True
client = TestClient(app)


@pytest.fixture
def auth_header_user_a():
    return {"Authorization": f"Bearer test-token-fin-a-{uuid.uuid4()}"}


@pytest.fixture
def auth_header_user_b():
    return {"Authorization": f"Bearer test-token-fin-b-{uuid.uuid4()}"}


def test_1_create_single_feasible_goal(auth_header_user_a):
    """1. One feasible goal creation."""
    payload = {
        "name": "Emergency Fund",
        "category": "Emergency Fund",
        "target_amount": "100000.00",
        "current_amount": "20000.00",
        "monthly_contribution": "10000.00",
        "deadline": (date.today() + timedelta(days=365)).isoformat(),
        "priority": "High",
    }
    res = client.post("/api/v1/financial/goals", json=payload, headers=auth_header_user_a)
    assert res.status_code == 201
    data = res.json()
    assert data["name"] == "Emergency Fund"
    assert Decimal(data["target_amount"]) == Decimal("100000.00")
    assert Decimal(data["remaining_amount"]) == Decimal("80000.00")
    assert data["is_feasible"] is True


def test_2_multiple_feasible_goals(auth_header_user_a):
    """2. Multiple feasible goals."""
    client.post(
        "/api/v1/financial/goals",
        json={
            "name": "Goal A",
            "category": "Travel",
            "target_amount": "50000.00",
            "current_amount": "10000.00",
            "monthly_contribution": "5000.00",
            "deadline": (date.today() + timedelta(days=300)).isoformat(),
            "priority": "Medium",
        },
        headers=auth_header_user_a,
    )
    client.post(
        "/api/v1/financial/goals",
        json={
            "name": "Goal B",
            "category": "Education",
            "target_amount": "100000.00",
            "current_amount": "20000.00",
            "monthly_contribution": "8000.00",
            "deadline": (date.today() + timedelta(days=400)).isoformat(),
            "priority": "High",
        },
        headers=auth_header_user_a,
    )

    res = client.get("/api/v1/financial/goals", headers=auth_header_user_a)
    assert res.status_code == 200
    goals = res.json()
    assert len(goals) >= 2


def test_3_monthly_capacity_conflict_detection(auth_header_user_a):
    """3. Monthly capacity conflict detection when required > capacity."""
    header = {"Authorization": f"Bearer test-token-conflict-{uuid.uuid4()}"}

    # Create goals whose total required monthly contribution exceeds available capacity (₹35,000)
    client.post(
        "/api/v1/financial/goals",
        json={
            "name": "Home Downpayment",
            "category": "Home",
            "target_amount": "3000000.00",
            "current_amount": "400000.00",
            "monthly_contribution": "15000.00",
            "deadline": (date.today() + timedelta(days=365 * 4)).isoformat(),
            "priority": "High",
        },
        headers=header,
    )
    client.post(
        "/api/v1/financial/goals",
        json={
            "name": "Higher Education",
            "category": "Education",
            "target_amount": "1000000.00",
            "current_amount": "200000.00",
            "monthly_contribution": "15000.00",
            "deadline": (date.today() + timedelta(days=365 * 2)).isoformat(),
            "priority": "High",
        },
        headers=header,
    )
    client.post(
        "/api/v1/financial/goals",
        json={
            "name": "Retirement Corpus",
            "category": "Retirement",
            "target_amount": "5000000.00",
            "current_amount": "500000.00",
            "monthly_contribution": "20000.00",
            "deadline": (date.today() + timedelta(days=365 * 10)).isoformat(),
            "priority": "High",
        },
        headers=header,
    )

    res = client.get("/api/v1/financial/analysis", headers=header)
    assert res.status_code == 200
    analysis = res.json()
    assert analysis["conflict"]["has_conflict"] is True
    assert Decimal(analysis["conflict"]["monthly_shortfall"]) > Decimal("0.00")
    assert len(analysis["scenarios"]) >= 1


def test_4_deadline_passed_infeasibility(auth_header_user_a):
    """4. Goal deadline passed marks goal as infeasible."""
    past_date = (date.today() - timedelta(days=30)).isoformat()
    res = client.post(
        "/api/v1/financial/goals",
        json={
            "name": "Past Goal",
            "category": "Other",
            "target_amount": "50000.00",
            "current_amount": "10000.00",
            "monthly_contribution": "2000.00",
            "deadline": past_date,
            "priority": "Low",
        },
        headers=auth_header_user_a,
    )
    assert res.status_code == 201
    data = res.json()
    assert data["months_remaining"] == 0
    assert data["is_feasible"] is False


def test_5_goal_already_completed(auth_header_user_a):
    """5. Goal already funded (current_amount >= target_amount)."""
    res = client.post(
        "/api/v1/financial/goals",
        json={
            "name": "Completed Bike Goal",
            "category": "Vehicle",
            "target_amount": "80000.00",
            "current_amount": "85000.00",
            "monthly_contribution": "0.00",
            "deadline": (date.today() + timedelta(days=60)).isoformat(),
            "priority": "Low",
        },
        headers=auth_header_user_a,
    )
    assert res.status_code == 201
    data = res.json()
    assert Decimal(data["remaining_amount"]) == Decimal("0.00")
    assert Decimal(data["required_monthly_contribution"]) == Decimal("0.00")
    assert data["is_feasible"] is True


def test_6_scenario_generation_and_application(auth_header_user_a):
    """6, 7, 8, 10. Scenario generation and application recalculation."""
    header = {"Authorization": f"Bearer test-token-scen-apply-{uuid.uuid4()}"}

    client.post(
        "/api/v1/financial/goals",
        json={
            "name": "Home Goal Test",
            "category": "Home",
            "target_amount": "3000000.00",
            "current_amount": "500000.00",
            "monthly_contribution": "10000.00",
            "deadline": (date.today() + timedelta(days=365 * 3)).isoformat(),
            "priority": "High",
        },
        headers=header,
    )

    # Generate scenarios
    sc_res = client.post("/api/v1/financial/scenarios/generate", headers=header)
    assert sc_res.status_code == 200
    scenarios = sc_res.json()
    assert len(scenarios) >= 1

    scenario_to_apply = scenarios[0]
    sc_id = scenario_to_apply["id"]

    # Apply scenario
    app_res = client.post(f"/api/v1/financial/scenarios/{sc_id}/apply", headers=header)
    assert app_res.status_code == 200
    assert app_res.json()["status"] == "ok"

    # Verify recalculation
    recalc_res = client.get("/api/v1/financial/analysis", headers=header)
    assert recalc_res.status_code == 200


def test_11_user_isolation(auth_header_user_a, auth_header_user_b):
    """11. User isolation enforcement."""
    create_res = client.post(
        "/api/v1/financial/goals",
        json={
            "name": "User B Secret Goal",
            "category": "Other",
            "target_amount": "100000.00",
            "current_amount": "0.00",
            "monthly_contribution": "5000.00",
            "deadline": (date.today() + timedelta(days=365)).isoformat(),
            "priority": "Medium",
        },
        headers=auth_header_user_b,
    )
    goal_id = create_res.json()["id"]

    # User A cannot retrieve B's goal
    get_res = client.get(f"/api/v1/financial/goals/{goal_id}", headers=auth_header_user_a)
    assert get_res.status_code == 404

    # User A cannot update B's goal
    patch_res = client.patch(f"/api/v1/financial/goals/{goal_id}", json={"name": "Hacked"}, headers=auth_header_user_a)
    assert patch_res.status_code == 404

    # User A cannot delete B's goal
    del_res = client.delete(f"/api/v1/financial/goals/{goal_id}", headers=auth_header_user_a)
    assert del_res.status_code == 404


def test_12_decimal_money_precision(auth_header_user_a):
    """12. Decimal monetary calculations preserve exact precision."""
    res = client.post(
        "/api/v1/financial/goals",
        json={
            "name": "Precision Test Goal",
            "category": "Other",
            "target_amount": "1234567.89",
            "current_amount": "12345.67",
            "monthly_contribution": "9999.99",
            "deadline": (date.today() + timedelta(days=365)).isoformat(),
            "priority": "Medium",
        },
        headers=auth_header_user_a,
    )
    assert res.status_code == 201
    data = res.json()
    assert Decimal(data["target_amount"]) == Decimal("1234567.89")
    assert Decimal(data["current_amount"]) == Decimal("12345.67")


def test_13_ai_interaction_chat_flow(auth_header_user_a):
    """Test AI interaction endpoint with natural language question."""
    chat_res = client.post(
        "/api/v1/financial/ai/chat",
        json={"message": "Can I afford all my goals?"},
        headers=auth_header_user_a,
    )
    assert chat_res.status_code == 200
    data = chat_res.json()
    assert "reply" in data
    assert "intent" in data
    assert len(data["reply"]) > 10
