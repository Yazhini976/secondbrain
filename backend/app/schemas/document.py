import uuid
from datetime import date, datetime
from typing import Optional, Dict
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

ALLOWED_DOCUMENT_CATEGORIES = {
    "Identity",
    "Financial",
    "Medical",
    "Insurance",
    "Education",
    "Property",
    "Vehicle",
    "Other",
}


class DocumentBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=255, description="Document title or name")
    name: Optional[str] = Field(None, max_length=255, description="Alias for document title")
    category: str = Field(..., description="Document category")
    description: Optional[str] = Field(None, max_length=2000, description="Optional description")
    issue_date: Optional[date] = Field(None, description="Document issue date")
    expiry_date: Optional[date] = Field(None, description="Document expiry date")
    file_name: Optional[str] = Field(None, max_length=255, description="Attachment file name")
    file_type: Optional[str] = Field(None, max_length=100, description="MIME type / file format")
    file_size: Optional[int] = Field(None, ge=0, description="File size in bytes")
    attachment_reference: Optional[str] = Field(None, max_length=1000, description="Secure reference to storage artifact")
    notes: Optional[str] = Field(None, max_length=2000, description="Optional notes")

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: str) -> str:
        if v not in ALLOWED_DOCUMENT_CATEGORIES:
            raise ValueError(
                f"Invalid document category '{v}'. Allowed categories: {', '.join(sorted(ALLOWED_DOCUMENT_CATEGORIES))}"
            )
        return v

    @model_validator(mode="after")
    def validate_dates_and_aliases(self) -> "DocumentBase":
        if self.name and not self.title:
            self.title = self.name.strip()
        elif self.title and not self.name:
            self.name = self.title.strip()

        if self.issue_date and self.expiry_date and self.expiry_date < self.issue_date:
            raise ValueError(
                f"expiry_date ({self.expiry_date}) cannot be earlier than issue_date ({self.issue_date})."
            )

        return self


class DocumentCreate(DocumentBase):
    """Schema for creating a new document metadata record."""
    pass


class DocumentUpdate(BaseModel):
    """Schema for updating an existing document. All fields optional."""
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    name: Optional[str] = Field(None, max_length=255)
    category: Optional[str] = None
    description: Optional[str] = Field(None, max_length=2000)
    issue_date: Optional[date] = None
    expiry_date: Optional[date] = None
    file_name: Optional[str] = Field(None, max_length=255)
    file_type: Optional[str] = Field(None, max_length=100)
    file_size: Optional[int] = Field(None, ge=0)
    attachment_reference: Optional[str] = Field(None, max_length=1000)
    notes: Optional[str] = Field(None, max_length=2000)

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ALLOWED_DOCUMENT_CATEGORIES:
            raise ValueError(
                f"Invalid document category '{v}'. Allowed categories: {', '.join(sorted(ALLOWED_DOCUMENT_CATEGORIES))}"
            )
        return v

    @model_validator(mode="after")
    def validate_dates(self) -> "DocumentUpdate":
        if self.name and not self.title:
            self.title = self.name.strip()

        if self.issue_date and self.expiry_date and self.expiry_date < self.issue_date:
            raise ValueError(
                f"expiry_date ({self.expiry_date}) cannot be earlier than issue_date ({self.issue_date})."
            )

        return self


class DocumentResponse(BaseModel):
    """Schema for returning document metadata with derived status."""
    id: uuid.UUID
    title: str
    name: str
    category: str
    description: Optional[str] = None
    issue_date: Optional[date] = None
    expiry_date: Optional[date] = None
    file_name: Optional[str] = None
    file_type: Optional[str] = None
    file_size: Optional[int] = None
    attachment_reference: Optional[str] = None
    notes: Optional[str] = None
    status: str = Field(..., description="Derived status: Active, Expiring Soon, Expired")
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class DocumentSummaryResponse(BaseModel):
    """Schema for document vault summary statistics."""
    total: int
    active: int
    expiring_soon: int
    expired: int
    category_counts: Dict[str, int]
