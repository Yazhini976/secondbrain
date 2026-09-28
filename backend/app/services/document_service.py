import uuid
from datetime import date
from typing import List, Optional, Dict
from sqlalchemy import select, or_
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.document import Document
from app.schemas.document import (
    DocumentCreate,
    DocumentUpdate,
    DocumentResponse,
    DocumentSummaryResponse,
    ALLOWED_DOCUMENT_CATEGORIES,
)

EXPIRING_SOON_DAYS = 30


def calculate_document_status(
    expiry_date: Optional[date],
    today: Optional[date] = None,
) -> str:
    """
    Derives document expiry status deterministically in Python domain layer.
    
    Rules (evaluated in priority order):
    1. If expiry_date is None -> "Active" (no expiry to track)
    2. If expiry_date < today -> "Expired"
    3. If 0 <= (expiry_date - today).days <= 30 -> "Expiring Soon"
    4. Otherwise -> "Active"
    """
    if expiry_date is None:
        return "Active"

    if today is None:
        today = date.today()

    if expiry_date < today:
        return "Expired"

    diff_days = (expiry_date - today).days
    if 0 <= diff_days <= EXPIRING_SOON_DAYS:
        return "Expiring Soon"

    return "Active"


def build_document_response(
    document: Document,
    today: Optional[date] = None,
) -> DocumentResponse:
    """
    Constructs a DocumentResponse schema from a Document ORM model with derived status.
    """
    status_str = calculate_document_status(document.expiry_date, today=today)
    doc_title = document.title or "Untitled Document"

    return DocumentResponse(
        id=document.id,
        title=doc_title,
        name=doc_title,
        category=document.category,
        description=document.description,
        issue_date=document.issue_date,
        expiry_date=document.expiry_date,
        file_name=document.file_name,
        file_type=document.file_type,
        file_size=document.file_size,
        attachment_reference=document.attachment_reference,
        notes=document.notes,
        status=status_str,
        created_at=document.created_at,
        updated_at=document.updated_at,
    )


def create_document(
    db: Session,
    current_user: User,
    document_in: DocumentCreate,
) -> DocumentResponse:
    """
    Creates a new document metadata record strictly scoped to current_user.
    Never trusts client-supplied user_id or status.
    """
    doc_title = (document_in.title or document_in.name or "Untitled Document").strip()

    document = Document(
        user_id=current_user.id,
        title=doc_title,
        category=document_in.category,
        description=document_in.description.strip() if document_in.description else None,
        issue_date=document_in.issue_date,
        expiry_date=document_in.expiry_date,
        file_name=document_in.file_name.strip() if document_in.file_name else None,
        file_type=document_in.file_type.strip() if document_in.file_type else None,
        file_size=document_in.file_size,
        attachment_reference=document_in.attachment_reference.strip() if document_in.attachment_reference else None,
        notes=document_in.notes.strip() if document_in.notes else None,
    )
    db.add(document)
    db.commit()
    db.refresh(document)

    return build_document_response(document)


def get_document(
    db: Session,
    current_user: User,
    document_id: uuid.UUID,
) -> Optional[DocumentResponse]:
    """
    Retrieves a document by ID ONLY if it belongs to current_user.
    Prevents horizontal privilege escalation.
    """
    stmt = select(Document).where(
        Document.id == document_id,
        Document.user_id == current_user.id,
    )
    doc = db.scalars(stmt).first()
    if not doc:
        return None
    return build_document_response(doc)


def get_document_orm(
    db: Session,
    current_user: User,
    document_id: uuid.UUID,
) -> Optional[Document]:
    """Internal helper to retrieve raw ORM model scoped to current_user."""
    stmt = select(Document).where(
        Document.id == document_id,
        Document.user_id == current_user.id,
    )
    return db.scalars(stmt).first()


def list_documents(
    db: Session,
    current_user: User,
    category: Optional[str] = None,
    search: Optional[str] = None,
    status_filter: Optional[str] = None,
    page: int = 1,
    page_size: int = 100,
) -> List[DocumentResponse]:
    """
    Lists documents belonging to current_user with optional category, search, and status filters.
    Supports case-insensitive search across title, category, description, and file_name.
    """
    stmt = select(Document).where(Document.user_id == current_user.id)

    # Category Filtering
    if category:
        if category not in ALLOWED_DOCUMENT_CATEGORIES:
            raise ValueError(
                f"Invalid document category '{category}'. Allowed categories: {', '.join(sorted(ALLOWED_DOCUMENT_CATEGORIES))}"
            )
        stmt = stmt.where(Document.category == category)

    # Text Search Filter across multiple fields
    if search and search.strip():
        term = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                Document.title.ilike(term),
                Document.category.ilike(term),
                Document.description.ilike(term),
                Document.file_name.ilike(term),
                Document.notes.ilike(term),
            )
        )

    # Order by updated_at DESC, title ASC
    stmt = stmt.order_by(Document.updated_at.desc(), Document.title.asc())

    orm_items = list(db.scalars(stmt).all())
    responses = [build_document_response(doc) for doc in orm_items]

    # Expiry Status Filter (Active, Expiring Soon, Expired)
    if status_filter and status_filter.strip():
        norm_status = status_filter.strip().lower().replace("_", " ")
        responses = [
            resp for resp in responses
            if resp.status.lower() == norm_status
        ]

    # Pagination
    safe_page = max(1, page)
    safe_page_size = min(max(1, page_size), 100)
    start_idx = (safe_page - 1) * safe_page_size
    end_idx = start_idx + safe_page_size

    return responses[start_idx:end_idx]


def update_document(
    db: Session,
    current_user: User,
    document_id: uuid.UUID,
    document_in: DocumentUpdate,
) -> Optional[DocumentResponse]:
    """
    Updates a document belonging to current_user.
    Recalculates status dynamically if expiry_date changes.
    """
    document = get_document_orm(db, current_user, document_id)
    if not document:
        return None

    if document_in.title is not None or document_in.name is not None:
        new_title = document_in.title or document_in.name
        if new_title:
            document.title = new_title.strip()
    if document_in.category is not None:
        document.category = document_in.category
    if document_in.description is not None:
        document.description = document_in.description.strip() if document_in.description else None
    if document_in.issue_date is not None:
        document.issue_date = document_in.issue_date
    if document_in.expiry_date is not None:
        document.expiry_date = document_in.expiry_date
    if document_in.file_name is not None:
        document.file_name = document_in.file_name.strip() if document_in.file_name else None
    if document_in.file_type is not None:
        document.file_type = document_in.file_type.strip() if document_in.file_type else None
    if document_in.file_size is not None:
        document.file_size = document_in.file_size
    if document_in.attachment_reference is not None:
        document.attachment_reference = document_in.attachment_reference.strip() if document_in.attachment_reference else None
    if document_in.notes is not None:
        document.notes = document_in.notes.strip() if document_in.notes else None

    # Validate model constraints after applying update
    if document.issue_date and document.expiry_date and document.expiry_date < document.issue_date:
        raise ValueError(
            f"expiry_date ({document.expiry_date}) cannot be earlier than issue_date ({document.issue_date})."
        )

    db.commit()
    db.refresh(document)

    return build_document_response(document)


def delete_document(
    db: Session,
    current_user: User,
    document_id: uuid.UUID,
) -> bool:
    """
    Deletes a document belonging to current_user.
    Returns True if deleted, False if not found or unauthorized.
    """
    document = get_document_orm(db, current_user, document_id)
    if not document:
        return False

    db.delete(document)
    db.commit()
    return True


def get_document_summary(
    db: Session,
    current_user: User,
) -> DocumentSummaryResponse:
    """
    Calculates document vault summary statistics for current_user.
    """
    stmt = select(Document).where(Document.user_id == current_user.id)
    documents = list(db.scalars(stmt).all())

    total = len(documents)
    active_count = 0
    expiring_soon_count = 0
    expired_count = 0

    category_counts: Dict[str, int] = {cat: 0 for cat in sorted(ALLOWED_DOCUMENT_CATEGORIES)}
    today = date.today()

    for doc in documents:
        if doc.category in category_counts:
            category_counts[doc.category] += 1

        st = calculate_document_status(doc.expiry_date, today=today)
        if st == "Active":
            active_count += 1
        elif st == "Expiring Soon":
            expiring_soon_count += 1
        elif st == "Expired":
            expired_count += 1

    return DocumentSummaryResponse(
        total=total,
        active=active_count,
        expiring_soon=expiring_soon_count,
        expired=expired_count,
        category_counts=category_counts,
    )
