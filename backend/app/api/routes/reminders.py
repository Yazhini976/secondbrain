import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.reminder import (
    ReminderCreate,
    ReminderUpdate,
    ReminderResponse,
)
from app.services import reminder_service

router = APIRouter()


@router.post("", response_model=ReminderResponse, status_code=status.HTTP_201_CREATED)
def create_reminder_endpoint(
    reminder_in: ReminderCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Creates a new reminder for the authenticated user."""
    try:
        return reminder_service.create_reminder(db, current_user, reminder_in)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))


@router.get("", response_model=List[ReminderResponse], status_code=status.HTTP_200_OK)
def list_reminders_endpoint(
    category: Optional[str] = Query(None, description="Filter by reminder category"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(100, ge=1, le=100, description="Page size limit"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lists reminders belonging to the authenticated user."""
    try:
        return reminder_service.list_reminders(
            db,
            current_user,
            category=category,
            page=page,
            page_size=page_size,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))


@router.get("/{reminder_id}", response_model=ReminderResponse, status_code=status.HTTP_200_OK)
def get_reminder_endpoint(
    reminder_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieves a single reminder by ID."""
    rem = reminder_service.get_reminder(db, current_user, reminder_id)
    if not rem:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reminder not found")
    return rem


@router.patch("/{reminder_id}", response_model=ReminderResponse, status_code=status.HTTP_200_OK)
def update_reminder_endpoint(
    reminder_id: uuid.UUID,
    reminder_in: ReminderUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Updates a reminder belonging to the authenticated user."""
    try:
        rem = reminder_service.update_reminder(db, current_user, reminder_id, reminder_in)
        if not rem:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reminder not found")
        return rem
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))


@router.delete("/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_reminder_endpoint(
    reminder_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Deletes a reminder belonging to the authenticated user."""
    deleted = reminder_service.delete_reminder(db, current_user, reminder_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reminder not found")
    return None
