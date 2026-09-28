import uuid
from datetime import datetime
from typing import Optional, TYPE_CHECKING
from sqlalchemy import String, Text, Boolean, DateTime, ForeignKey, CheckConstraint, Index, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.user import User


class Reminder(Base):
    """
    Reminder Model.
    Supports manual user reminders as well as auto-generated reminders derived
    from document expiry dates or investment due dates.
    
    IMPORTANT Architectural Rules:
    1. Reminder status (Upcoming, Due Today, Overdue, Completed) is DERIVED from
       is_completed + due_at + current time in the domain layer.
    2. UniqueConstraint on (user_id, source, linked_entity_type, linked_entity_id)
       prevents duplicate automatic reminders for the same entity while allowing
       multiple manual reminders (where linked_entity_id is NULL).
    """
    __tablename__ = "reminders"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    due_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    category: Mapped[str] = mapped_column(String(50), nullable=False, default="Personal")
    priority: Mapped[str] = mapped_column(String(20), nullable=False, default="Medium")
    is_completed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    source: Mapped[str] = mapped_column(String(50), nullable=False, default="manual")
    linked_entity_type: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    linked_entity_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="reminders")

    __table_args__ = (
        CheckConstraint("category IN ('Personal', 'Document', 'Investment', 'Other')", name="ck_reminder_category_valid"),
        CheckConstraint("priority IN ('Low', 'Medium', 'High')", name="ck_reminder_priority_valid"),
        CheckConstraint("source IN ('manual', 'documentExpiry', 'investmentDue')", name="ck_reminder_source_valid"),
        UniqueConstraint(
            "user_id", "source", "linked_entity_type", "linked_entity_id",
            name="uq_auto_reminder_source_entity"
        ),
        Index("ix_reminders_user_due_at", "user_id", "due_at"),
    )
