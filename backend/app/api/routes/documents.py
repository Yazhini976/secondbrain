import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.document import (
    DocumentCreate,
    DocumentUpdate,
    DocumentResponse,
    DocumentSummaryResponse,
)
from app.services import document_service

router = APIRouter()


@router.post("", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
def create_document_endpoint(
    document_in: DocumentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Creates document metadata record for the authenticated user.
    """
    try:
        return document_service.create_document(db, current_user, document_in)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))


@router.get("", response_model=List[DocumentResponse], status_code=status.HTTP_200_OK)
def list_documents_endpoint(
    category: Optional[str] = Query(None, description="Filter by document category"),
    search: Optional[str] = Query(None, description="Search term for title, category, description, file_name, or notes"),
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by derived status: active, expiring_soon, expired"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(100, ge=1, le=100, description="Page size limit"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Lists documents belonging to the authenticated user with optional category, search, and status filters.
    """
    try:
        return document_service.list_documents(
            db,
            current_user,
            category=category,
            search=search,
            status_filter=status_filter,
            page=page,
            page_size=page_size,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))


@router.get("/summary", response_model=DocumentSummaryResponse, status_code=status.HTTP_200_OK)
def get_document_summary_endpoint(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Retrieves document vault summary statistics for the authenticated user.
    """
    return document_service.get_document_summary(db, current_user)


@router.get("/{document_id}", response_model=DocumentResponse, status_code=status.HTTP_200_OK)
def get_document_endpoint(
    document_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Retrieves a single document metadata record by ID.
    Returns 404 if the document does not exist or belongs to another user.
    """
    doc = document_service.get_document(db, current_user, document_id)
    if not doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")
    return doc


@router.patch("/{document_id}", response_model=DocumentResponse, status_code=status.HTTP_200_OK)
def update_document_endpoint(
    document_id: uuid.UUID,
    document_in: DocumentUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Updates document metadata belonging to the authenticated user.
    """
    try:
        doc = document_service.update_document(db, current_user, document_id, document_in)
        if not doc:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")
        return doc
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_document_endpoint(
    document_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Deletes a document belonging to the authenticated user.
    """
    deleted = document_service.delete_document(db, current_user, document_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")
    return None
