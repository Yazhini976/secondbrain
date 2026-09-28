import uuid
from datetime import datetime, date
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.reminder import Reminder
from app.schemas.reminder import (
    ReminderCreate,
    ReminderUpdate,
    ReminderResponse,
)


def calculate_reminder_status(
    due_at: datetime,
    is_completed: bool,
    today: Optional[date] = None,
) -> str:
    """
    Derives reminder status deterministically.
    
    Rules:
    1. If is_completed is True -> "Completed"
    2. If due_at.date() < today -> "Overdue"
    3. If due_at.date() == today -> "Due Today"
    4. Otherwise -> "Upcoming"
    """
    if is_completed:
        return "Completed"

    if today is None:
        today = date.today()

    due_date = due_at.date()
    if due_date < today:
        return "Overdue"
    elif due_date == today:
        return "Due Today"
    else:
        return "Upcoming"


def build_reminder_response(
    reminder: Reminder,
    today: Optional[date] = None,
) -> ReminderResponse:
    """Constructs a ReminderResponse schema with derived status."""
    st = calculate_reminder_status(reminder.due_at, reminder.is_completed, today=today)
    return ReminderResponse(
        id=reminder.id,
        title=reminder.title,
        description=reminder.description,
        due_at=reminder.due_at,
        category=reminder.category,
        priority=reminder.priority,
        is_completed=reminder.is_completed,
        source=reminder.source,
        linked_entity_type=reminder.linked_entity_type,
        linked_entity_id=reminder.linked_entity_id,
        status=st,
        created_at=reminder.created_at,
        updated_at=reminder.updated_at,
    )


def create_reminder(
    db: Session,
    current_user: User,
    reminder_in: ReminderCreate,
) -> ReminderResponse:
    """Creates a reminder record strictly scoped to current_user."""
    reminder = Reminder(
        user_id=current_user.id,
        title=reminder_in.title.strip(),
        description=reminder_in.description.strip() if reminder_in.description else None,
        due_at=reminder_in.due_at,
        category=reminder_in.category,
        priority=reminder_in.priority,
        is_completed=reminder_in.is_completed,
        source=reminder_in.source,
        linked_entity_type=reminder_in.linked_entity_type,
        linked_entity_id=reminder_in.linked_entity_id,
    )
    db.add(reminder)
    db.commit()
    db.refresh(reminder)
    return build_reminder_response(reminder)


def get_reminder(
    db: Session,
    current_user: User,
    reminder_id: uuid.UUID,
) -> Optional[ReminderResponse]:
    """Retrieves a reminder by ID scoped to current_user."""
    stmt = select(Reminder).where(
        Reminder.id == reminder_id,
        Reminder.user_id == current_user.id,
    )
    rem = db.scalars(stmt).first()
    if not rem:
        return None
    return build_reminder_response(rem)


def get_reminder_orm(
    db: Session,
    current_user: User,
    reminder_id: uuid.UUID,
) -> Optional[Reminder]:
    """Helper to retrieve raw ORM model scoped to current_user."""
    stmt = select(Reminder).where(
        Reminder.id == reminder_id,
        Reminder.user_id == current_user.id,
    )
    return db.scalars(stmt).first()


def list_reminders(
    db: Session,
    current_user: User,
    category: Optional[str] = None,
    page: int = 1,
    page_size: int = 100,
) -> List[ReminderResponse]:
    """Lists reminders belonging to current_user."""
    stmt = select(Reminder).where(Reminder.user_id == current_user.id)

    if category:
        stmt = stmt.where(Reminder.category == category)

    stmt = stmt.order_by(Reminder.due_at.asc(), Reminder.created_at.desc())

    orm_items = list(db.scalars(stmt).all())
    responses = [build_reminder_response(rem) for rem in orm_items]

    safe_page = max(1, page)
    safe_page_size = min(max(1, page_size), 100)
    start_idx = (safe_page - 1) * safe_page_size
    end_idx = start_idx + safe_page_size

    return responses[start_idx:end_idx]


def update_reminder(
    db: Session,
    current_user: User,
    reminder_id: uuid.UUID,
    reminder_in: ReminderUpdate,
) -> Optional[ReminderResponse]:
    """Updates a reminder belonging to current_user."""
    reminder = get_reminder_orm(db, current_user, reminder_id)
    if not reminder:
        return None

    if reminder_in.title is not None:
        reminder.title = reminder_in.title.strip()
    if reminder_in.description is not None:
        reminder.description = reminder_in.description.strip() if reminder_in.description else None
    if reminder_in.due_at is not None:
        reminder.due_at = reminder_in.due_at
    if reminder_in.category is not None:
        reminder.category = reminder_in.category
    if reminder_in.priority is not None:
        reminder.priority = reminder_in.priority
    if reminder_in.is_completed is not None:
        reminder.is_completed = reminder_in.is_completed
    if reminder_in.source is not None:
        reminder.source = reminder_in.source
    if reminder_in.linked_entity_type is not None:
        reminder.linked_entity_type = reminder_in.linked_entity_type
    if reminder_in.linked_entity_id is not None:
        reminder.linked_entity_id = reminder_in.linked_entity_id

    db.commit()
    db.refresh(reminder)
    return build_reminder_response(reminder)


def delete_reminder(
    db: Session,
    current_user: User,
    reminder_id: uuid.UUID,
) -> bool:
    """Deletes a reminder belonging to current_user."""
    reminder = get_reminder_orm(db, current_user, reminder_id)
    if not reminder:
        return False
    db.delete(reminder)
    db.commit()
    return True
