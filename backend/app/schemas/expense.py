import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional, Dict
from pydantic import BaseModel, ConfigDict, Field, field_validator

ALLOWED_EXPENSE_CATEGORIES = {
    "Food & Dining",
    "Transport",
    "Shopping",
    "Bills & Utilities",
    "Other",
}


class ExpenseBase(BaseModel):
    merchant: str = Field(..., min_length=1, max_length=255, description="Merchant name or transaction description")
    amount: Decimal = Field(..., gt=0, description="Expense amount strictly greater than zero")
    category: str = Field(..., description="Expense category")
    transaction_date: date = Field(..., description="Date of expense transaction")
    notes: Optional[str] = Field(None, max_length=1000, description="Optional notes")

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: str) -> str:
        if v not in ALLOWED_EXPENSE_CATEGORIES:
            raise ValueError(
                f"Invalid expense category '{v}'. Allowed categories: {', '.join(sorted(ALLOWED_EXPENSE_CATEGORIES))}"
            )
        return v


class ExpenseCreate(ExpenseBase):
    """Schema for creating a new expense."""
    pass


class ExpenseUpdate(BaseModel):
    """Schema for updating an existing expense. All fields optional."""
    merchant: Optional[str] = Field(None, min_length=1, max_length=255)
    amount: Optional[Decimal] = Field(None, gt=0)
    category: Optional[str] = None
    transaction_date: Optional[date] = None
    notes: Optional[str] = Field(None, max_length=1000)

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ALLOWED_EXPENSE_CATEGORIES:
            raise ValueError(
                f"Invalid expense category '{v}'. Allowed categories: {', '.join(sorted(ALLOWED_EXPENSE_CATEGORIES))}"
            )
        return v


class ExpenseResponse(ExpenseBase):
    """Schema for returning expense details."""
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ExpenseMonthlySummary(BaseModel):
    """Schema for monthly expense totals and category breakdowns."""
    year: int
    month: int
    total: Decimal
    category_totals: Dict[str, Decimal]
