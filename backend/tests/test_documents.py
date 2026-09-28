import uuid
from datetime import date, timedelta
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.config import settings
from app.services.document_service import calculate_document_status

settings.TESTING = True
client = TestClient(app)


@pytest.fixture
def auth_header_user_a():
    return {"Authorization": f"Bearer test-token-doc-a-{uuid.uuid4()}"}


@pytest.fixture
def auth_header_user_b():
    return {"Authorization": f"Bearer test-token-doc-b-{uuid.uuid4()}"}


def test_1_create_document_success(auth_header_user_a):
    """1. Authenticated user can create document."""
    payload = {
        "title": "Passport",
        "category": "Identity",
        "description": "Personal passport",
        "issue_date": "2020-01-15",
        "expiry_date": (date.today() + timedelta(days=365)).isoformat(),
        "file_name": "passport.pdf",
        "file_type": "application/pdf",
        "file_size": 204800,
        "attachment_reference": "doc_ref_passport_001",
        "notes": "Keep safe in vault",
    }
    res = client.post("/api/v1/documents", json=payload, headers=auth_header_user_a)
    assert res.status_code == 201
    data = res.json()
    assert data["title"] == "Passport"
    assert data["name"] == "Passport"
    assert data["category"] == "Identity"
    assert data["description"] == "Personal passport"
    assert data["issue_date"] == "2020-01-15"
    assert data["file_name"] == "passport.pdf"
    assert data["file_type"] == "application/pdf"
    assert data["file_size"] == 204800
    assert data["attachment_reference"] == "doc_ref_passport_001"
    assert data["status"] == "Active"
    assert "id" in data


def test_2_list_own_documents(auth_header_user_a):
    """2. Authenticated user can list own documents."""
    client.post(
        "/api/v1/documents",
        json={"title": "Driving License", "category": "Vehicle"},
        headers=auth_header_user_a,
    )
    res = client.get("/api/v1/documents", headers=auth_header_user_a)
    assert res.status_code == 200
    data = res.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    assert any(doc["title"] == "Driving License" for doc in data)


def test_3_retrieve_own_document(auth_header_user_a):
    """3. Authenticated user can retrieve own document."""
    create_res = client.post(
        "/api/v1/documents",
        json={"title": "Tax Return 2025", "category": "Financial"},
        headers=auth_header_user_a,
    )
    doc_id = create_res.json()["id"]

    res = client.get(f"/api/v1/documents/{doc_id}", headers=auth_header_user_a)
    assert res.status_code == 200
    data = res.json()
    assert data["id"] == doc_id
    assert data["title"] == "Tax Return 2025"


def test_4_update_own_document(auth_header_user_a):
    """4. Authenticated user can update own document."""
    create_res = client.post(
        "/api/v1/documents",
        json={"title": "Health Policy", "category": "Insurance"},
        headers=auth_header_user_a,
    )
    doc_id = create_res.json()["id"]

    update_payload = {
        "title": "Health Insurance Policy 2026",
        "description": "Updated policy coverage",
    }
    res = client.patch(f"/api/v1/documents/{doc_id}", json=update_payload, headers=auth_header_user_a)
    assert res.status_code == 200
    data = res.json()
    assert data["title"] == "Health Insurance Policy 2026"
    assert data["description"] == "Updated policy coverage"


def test_5_delete_own_document(auth_header_user_a):
    """5. Authenticated user can delete own document."""
    create_res = client.post(
        "/api/v1/documents",
        json={"title": "Temporary Receipt", "category": "Other"},
        headers=auth_header_user_a,
    )
    doc_id = create_res.json()["id"]

    res = client.delete(f"/api/v1/documents/{doc_id}", headers=auth_header_user_a)
    assert res.status_code == 204

    # Verify deletion
    get_res = client.get(f"/api/v1/documents/{doc_id}", headers=auth_header_user_a)
    assert get_res.status_code == 404


def test_6_unauthenticated_request_rejected():
    """6. Unauthenticated request rejected."""
    res = client.get("/api/v1/documents")
    assert res.status_code == 401

    res = client.post("/api/v1/documents", json={"title": "No Auth", "category": "Other"})
    assert res.status_code == 401


def test_7_user_a_cannot_retrieve_user_b_document(auth_header_user_a, auth_header_user_b):
    """7. User A cannot retrieve User B's document."""
    create_res = client.post(
        "/api/v1/documents",
        json={"title": "User B Secret Doc", "category": "Identity"},
        headers=auth_header_user_b,
    )
    doc_id = create_res.json()["id"]

    res = client.get(f"/api/v1/documents/{doc_id}", headers=auth_header_user_a)
    assert res.status_code == 404


def test_8_user_a_cannot_update_user_b_document(auth_header_user_a, auth_header_user_b):
    """8. User A cannot update User B's document."""
    create_res = client.post(
        "/api/v1/documents",
        json={"title": "User B Doc", "category": "Financial"},
        headers=auth_header_user_b,
    )
    doc_id = create_res.json()["id"]

    res = client.patch(
        f"/api/v1/documents/{doc_id}",
        json={"title": "Hacked Title"},
        headers=auth_header_user_a,
    )
    assert res.status_code == 404


def test_9_user_a_cannot_delete_user_b_document(auth_header_user_a, auth_header_user_b):
    """9. User A cannot delete User B's document."""
    create_res = client.post(
        "/api/v1/documents",
        json={"title": "User B Protected Doc", "category": "Property"},
        headers=auth_header_user_b,
    )
    doc_id = create_res.json()["id"]

    res = client.delete(f"/api/v1/documents/{doc_id}", headers=auth_header_user_a)
    assert res.status_code == 404

    # Verify B's document still exists
    get_res = client.get(f"/api/v1/documents/{doc_id}", headers=auth_header_user_b)
    assert get_res.status_code == 200


def test_10_invalid_category_rejected(auth_header_user_a):
    """10. Invalid category rejected."""
    payload = {"title": "Random File", "category": "InvalidCategoryName"}
    res = client.post("/api/v1/documents", json=payload, headers=auth_header_user_a)
    assert res.status_code == 422


def test_11_invalid_expiry_date_rejected(auth_header_user_a):
    """11. Invalid expiry date (before issue date) rejected."""
    payload = {
        "title": "Invalid Dates Doc",
        "category": "Education",
        "issue_date": "2026-05-10",
        "expiry_date": "2026-05-01",
    }
    res = client.post("/api/v1/documents", json=payload, headers=auth_header_user_a)
    assert res.status_code == 422


def test_12_expired_status_calculated_correctly(auth_header_user_a):
    """12. Expired status calculated correctly."""
    past_date = (date.today() - timedelta(days=5)).isoformat()
    res = client.post(
        "/api/v1/documents",
        json={"title": "Expired Visa", "category": "Identity", "expiry_date": past_date},
        headers=auth_header_user_a,
    )
    assert res.status_code == 201
    assert res.json()["status"] == "Expired"
    assert calculate_document_status(date.today() - timedelta(days=1)) == "Expired"


def test_13_expiring_soon_status_calculated_correctly(auth_header_user_a):
    """13. Expiring Soon status calculated correctly."""
    soon_date = (date.today() + timedelta(days=15)).isoformat()
    res = client.post(
        "/api/v1/documents",
        json={"title": "Expiring Insurance", "category": "Insurance", "expiry_date": soon_date},
        headers=auth_header_user_a,
    )
    assert res.status_code == 201
    assert res.json()["status"] == "Expiring Soon"
    assert calculate_document_status(date.today() + timedelta(days=20)) == "Expiring Soon"


def test_14_active_status_calculated_correctly(auth_header_user_a):
    """14. Active status calculated correctly."""
    far_future = (date.today() + timedelta(days=100)).isoformat()
    res = client.post(
        "/api/v1/documents",
        json={"title": "Long Term Warranty", "category": "Other", "expiry_date": far_future},
        headers=auth_header_user_a,
    )
    assert res.status_code == 201
    assert res.json()["status"] == "Active"

    # Also check no expiry_date -> Active
    res_no_exp = client.post(
        "/api/v1/documents",
        json={"title": "Birth Certificate", "category": "Identity"},
        headers=auth_header_user_a,
    )
    assert res_no_exp.status_code == 201
    assert res_no_exp.json()["status"] == "Active"


def test_15_search_works(auth_header_user_a):
    """15. Search works across fields."""
    client.post(
        "/api/v1/documents",
        json={"title": "Unique Searchable Passport", "category": "Identity"},
        headers=auth_header_user_a,
    )

    res = client.get("/api/v1/documents?search=Searchable", headers=auth_header_user_a)
    assert res.status_code == 200
    data = res.json()
    assert len(data) >= 1
    assert any("Searchable" in d["title"] for d in data)


def test_16_category_filtering_works(auth_header_user_a):
    """16. Category filtering works."""
    client.post(
        "/api/v1/documents",
        json={"title": "Medical Report", "category": "Medical"},
        headers=auth_header_user_a,
    )

    res = client.get("/api/v1/documents?category=Medical", headers=auth_header_user_a)
    assert res.status_code == 200
    data = res.json()
    assert all(d["category"] == "Medical" for d in data)


def test_17_search_plus_category_filtering_works(auth_header_user_a):
    """17. Search + category filtering works simultaneously."""
    client.post(
        "/api/v1/documents",
        json={"title": "Car RC Smartcard", "category": "Vehicle"},
        headers=auth_header_user_a,
    )

    res = client.get("/api/v1/documents?category=Vehicle&search=Smartcard", headers=auth_header_user_a)
    assert res.status_code == 200
    data = res.json()
    assert len(data) >= 1
    assert all(d["category"] == "Vehicle" and "Smartcard" in d["title"] for d in data)


def test_18_summary_counts_are_correct(auth_header_user_a):
    """18. Summary counts are correct and user-scoped."""
    # Create isolated user fixture headers
    user_summary_header = {"Authorization": f"Bearer test-token-doc-summary-{uuid.uuid4()}"}

    client.post(
        "/api/v1/documents",
        json={"title": "Active Doc", "category": "Identity", "expiry_date": (date.today() + timedelta(days=90)).isoformat()},
        headers=user_summary_header,
    )
    client.post(
        "/api/v1/documents",
        json={"title": "Expiring Soon Doc", "category": "Insurance", "expiry_date": (date.today() + timedelta(days=10)).isoformat()},
        headers=user_summary_header,
    )
    client.post(
        "/api/v1/documents",
        json={"title": "Expired Doc", "category": "Vehicle", "expiry_date": (date.today() - timedelta(days=10)).isoformat()},
        headers=user_summary_header,
    )

    res = client.get("/api/v1/documents/summary", headers=user_summary_header)
    assert res.status_code == 200
    summary = res.json()
    assert summary["total"] == 3
    assert summary["active"] == 1
    assert summary["expiring_soon"] == 1
    assert summary["expired"] == 1
    assert summary["category_counts"]["Identity"] == 1
    assert summary["category_counts"]["Insurance"] == 1
    assert summary["category_counts"]["Vehicle"] == 1


def test_19_attachment_metadata_persisted_correctly(auth_header_user_a):
    """19. Attachment metadata is persisted correctly."""
    payload = {
        "title": "House Deed",
        "category": "Property",
        "file_name": "house_deed_scan.pdf",
        "file_type": "application/pdf",
        "file_size": 5242880,
        "attachment_reference": "storage/docs/house_deed_encrypted.bin",
    }
    create_res = client.post("/api/v1/documents", json=payload, headers=auth_header_user_a)
    assert create_res.status_code == 201
    data = create_res.json()
    assert data["file_name"] == "house_deed_scan.pdf"
    assert data["file_type"] == "application/pdf"
    assert data["file_size"] == 5242880
    assert data["attachment_reference"] == "storage/docs/house_deed_encrypted.bin"


def test_20_status_recalculates_after_expiry_date_update(auth_header_user_a):
    """20. Status recalculates after expiry_date update."""
    # Create an initially active document
    create_res = client.post(
        "/api/v1/documents",
        json={
            "title": "Passport Renewal Test",
            "category": "Identity",
            "expiry_date": (date.today() + timedelta(days=100)).isoformat(),
        },
        headers=auth_header_user_a,
    )
    doc_id = create_res.json()["id"]
    assert create_res.json()["status"] == "Active"

    # Update expiry date to expired date
    past_date = (date.today() - timedelta(days=10)).isoformat()
    update_res = client.patch(
        f"/api/v1/documents/{doc_id}",
        json={"expiry_date": past_date},
        headers=auth_header_user_a,
    )
    assert update_res.status_code == 200
    assert update_res.json()["status"] == "Expired"
