# Second Brain — FastAPI Backend API (Expenses, Investments & Documents)

Clean backend foundation for **Second Brain** built using FastAPI, Firebase Admin SDK Authentication, SQLAlchemy 2.x, psycopg (PostgreSQL), Pydantic v2, and Alembic.

---

## 📋 Requirements

- **Python**: `3.10+` (Tested on `3.13.2`)
- **Database**: PostgreSQL (`second_brain`)
- **Driver**: `psycopg` v3 (modern PostgreSQL driver)
- **Auth Provider**: Firebase Authentication (via `firebase-admin` SDK)

> ⚠️ **IMPORTANT ARCHITECTURAL RULES**:
> 1. SQLite, Drift, sqflite, Hive, Isar, or any local database alternatives are **strictly forbidden** in this application.
> 2. **User-Scoped Isolation**: Every database query strictly filters by `user_id = current_user.id`. Client-submitted `user_id` values in request bodies or query parameters are NEVER trusted for authorization.
> 3. **Monetary Precision**: Amounts strictly use `NUMERIC(14,2)` / Python `Decimal` — floating point arithmetic is never used for financial calculations.
> 4. **Derived Status & Progress**: Investment and Document status (`Active`, `Expiring Soon`, `Expired`, `On Track`, `Due Soon`, `Overdue`, `Completed`) are derived deterministically server-side in Python. Client input for status is never trusted as authoritative.
> 5. **Attachment Metadata Only**: Binary file content is not stored in PostgreSQL. Secure attachment metadata (`file_name`, `file_type`, `file_size`, `attachment_reference`) is persisted for future encrypted object storage.

---

## 📄 Documents REST API Endpoints

All endpoints require HTTP Header: `Authorization: Bearer <FIREBASE_ID_TOKEN>`

| Method | Endpoint | Description | Status Code |
|---|---|---|---|
| `POST` | `/api/v1/documents` | Create document metadata record | `201 Created` |
| `GET` | `/api/v1/documents` | List authenticated user's documents (Optional filters: `category`, `search`, `status`, `page`, `page_size`) | `200 OK` |
| `GET` | `/api/v1/documents/summary` | Get document vault summary (total count, active, expiring soon, expired, and category counts) | `200 OK` |
| `GET` | `/api/v1/documents/{document_id}` | Retrieve single document metadata record by UUID | `200 OK` / `404` |
| `PATCH` | `/api/v1/documents/{document_id}` | Update document details (recalculates status if `expiry_date` changes) | `200 OK` / `404` |
| `DELETE` | `/api/v1/documents/{document_id}` | Delete document metadata by UUID | `204 No Content` / `404` |

---

## 🏷️ Document Categories & Expiry Logic

### Allowed Document Categories:
- `Identity`
- `Financial`
- `Medical`
- `Insurance`
- `Education`
- `Property`
- `Vehicle`
- `Other`

### Derived Document Expiry Status Rules (Warning Window: 30 days):
1. **No Expiry Date (`expiry_date == None`)** -> `Active`
2. **`expiry_date < today`** -> `Expired`
3. **`0 <= (expiry_date - today).days <= 30`** -> `Expiring Soon`
4. **Otherwise** -> `Active`

---

## 💵 Expenses REST API Endpoints

All endpoints require HTTP Header: `Authorization: Bearer <FIREBASE_ID_TOKEN>`

| Method | Endpoint | Description | Status Code |
|---|---|---|---|
| `POST` | `/api/v1/expenses` | Create a new expense transaction | `201 Created` |
| `GET` | `/api/v1/expenses` | List authenticated user's expenses (Optional filters: `year`, `month`, `category`, `page`, `page_size`) | `200 OK` |
| `GET` | `/api/v1/expenses/summary` | Calculate monthly spending total and category breakdown (`year`, `month`) | `200 OK` |
| `GET` | `/api/v1/expenses/{expense_id}` | Retrieve single expense by UUID | `200 OK` / `404` |
| `PATCH` | `/api/v1/expenses/{expense_id}` | Update expense details (partial update) | `200 OK` / `404` |
| `DELETE` | `/api/v1/expenses/{expense_id}` | Delete an expense by UUID | `204 No Content` / `404` |

---

## 📈 Investments REST API Endpoints

All endpoints require HTTP Header: `Authorization: Bearer <FIREBASE_ID_TOKEN>`

| Method | Endpoint | Description | Status Code |
|---|---|---|---|
| `POST` | `/api/v1/investments` | Create a new investment record | `201 Created` |
| `GET` | `/api/v1/investments` | List authenticated user's investments (Optional filter: `type`, `page`, `page_size`) | `200 OK` |
| `GET` | `/api/v1/investments/summary` | Get portfolio summary (total invested, monthly contribution, status count breakdowns) | `200 OK` |
| `GET` | `/api/v1/investments/{investment_id}` | Retrieve single investment by UUID | `200 OK` / `404` |
| `PATCH` | `/api/v1/investments/{investment_id}` | Update investment details (recalculates status & progress) | `200 OK` / `404` |
| `DELETE` | `/api/v1/investments/{investment_id}` | Delete an investment by UUID | `204 No Content` / `404` |

---

## 💡 Example Document Requests & Responses

### 1. Create Document Metadata (`POST /api/v1/documents`)

**Request Payload:**
```json
{
  "title": "Passport",
  "category": "Identity",
  "description": "Personal passport scan",
  "issue_date": "2020-01-15",
  "expiry_date": "2030-01-15",
  "file_name": "passport.pdf",
  "file_type": "application/pdf",
  "file_size": 204800,
  "attachment_reference": "storage/docs/passport_encrypted.bin",
  "notes": "Keep safe in vault"
}
```

**Response (`201 Created`):**
```json
{
  "id": "e4d7a8bf-1234-4567-89ab-cdef01234567",
  "title": "Passport",
  "name": "Passport",
  "category": "Identity",
  "description": "Personal passport scan",
  "issue_date": "2020-01-15",
  "expiry_date": "2030-01-15",
  "file_name": "passport.pdf",
  "file_type": "application/pdf",
  "file_size": 204800,
  "attachment_reference": "storage/docs/passport_encrypted.bin",
  "notes": "Keep safe in vault",
  "status": "Active",
  "created_at": "2026-09-28T15:00:00.000Z",
  "updated_at": "2026-09-28T15:00:00.000Z"
}
```

### 2. Get Document Vault Summary (`GET /api/v1/documents/summary`)

**Response (`200 OK`):**
```json
{
  "total": 12,
  "active": 8,
  "expiring_soon": 3,
  "expired": 1,
  "category_counts": {
    "Education": 1,
    "Financial": 2,
    "Identity": 3,
    "Insurance": 2,
    "Medical": 1,
    "Other": 1,
    "Property": 1,
    "Vehicle": 1
  }
}
```

---

## ⚙️ Setup Instructions

### 1. Virtual Environment & Dependencies

```bash
# Activate virtual environment
.\.venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt
```

### 2. Run Database Migrations

```bash
alembic upgrade head
```

### 3. Run FastAPI Dev Server

```bash
uvicorn app.main:app --reload
```
Interactive Swagger Docs: `http://localhost:8000/api/v1/docs`

### 4. Run Test Suite

```bash
.\.venv\Scripts\pytest -v
```
- Runs 72 automated backend tests covering authentication, foundation validation, PostgreSQL live schema checks, Expenses CRUD, Investments CRUD, and all 20 Documents CRUD, derived status, search, category filter, and summary test cases.
