import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator

ALLOWED_REMINDER_CATEGORIES = {"Personal", "Document", "Investment", "Other"}
ALLOWED_REMINDER_PRIORITIES = {"Low", "Medium", "High"}
ALLOWED_REMINDER_SOURCES = {"manual", "documentExpiry", "investmentDue"}


class ReminderBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=255, description="Reminder title")
    description: Optional[str] = Field(None, max_length=2000, description="Optional description")
    due_at: datetime = Field(..., description="Due timestamp (UTC / ISO)")
    category: str = Field("Personal", description="Reminder category")
    priority: str = Field("Medium", description="Priority level: Low, Medium, High")
    is_completed: bool = Field(False, description="Completion status")
    source: str = Field("manual", description="Source of reminder")
    linked_entity_type: Optional[str] = Field(None, max_length=50)
    linked_entity_id: Optional[uuid.UUID] = Field(None)

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: str) -> str:
        if v not in ALLOWED_REMINDER_CATEGORIES:
            raise ValueError(
                f"Invalid category '{v}'. Allowed: {', '.join(sorted(ALLOWED_REMINDER_CATEGORIES))}"
            )
        return v

    @field_validator("priority")
    @classmethod
    def validate_priority(cls, v: str) -> str:
        if v not in ALLOWED_REMINDER_PRIORITIES:
            raise ValueError(
                f"Invalid priority '{v}'. Allowed: {', '.join(sorted(ALLOWED_REMINDER_PRIORITIES))}"
            )
        return v

    @field_validator("source")
    @classmethod
    def validate_source(cls, v: str) -> str:
        if v not in ALLOWED_REMINDER_SOURCES:
            raise ValueError(
                f"Invalid source '{v}'. Allowed: {', '.join(sorted(ALLOWED_REMINDER_SOURCES))}"
            )
        return v


class ReminderCreate(ReminderBase):
    pass


class ReminderUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=2000)
    due_at: Optional[datetime] = None
    category: Optional[str] = None
    priority: Optional[str] = None
    is_completed: Optional[bool] = None
    source: Optional[str] = None
    linked_entity_type: Optional[str] = Field(None, max_length=50)
    linked_entity_id: Optional[uuid.UUID] = None

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ALLOWED_REMINDER_CATEGORIES:
            raise ValueError(
                f"Invalid category '{v}'. Allowed: {', '.join(sorted(ALLOWED_REMINDER_CATEGORIES))}"
            )
        return v

    @field_validator("priority")
    @classmethod
    def validate_priority(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ALLOWED_REMINDER_PRIORITIES:
            raise ValueError(
                f"Invalid priority '{v}'. Allowed: {', '.join(sorted(ALLOWED_REMINDER_PRIORITIES))}"
            )
        return v

    @field_validator("source")
    @classmethod
    def validate_source(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ALLOWED_REMINDER_SOURCES:
            raise ValueError(
                f"Invalid source '{v}'. Allowed: {', '.join(sorted(ALLOWED_REMINDER_SOURCES))}"
            )
        return v


class ReminderResponse(BaseModel):
    id: uuid.UUID
    title: str
    description: Optional[str] = None
    due_at: datetime
    category: str
    priority: str
    is_completed: bool
    source: str
    linked_entity_type: Optional[str] = None
    linked_entity_id: Optional[uuid.UUID] = None
    status: str = Field(..., description="Derived status: Completed, Due Today, Overdue, Upcoming")
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
