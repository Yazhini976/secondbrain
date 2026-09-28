import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

ALLOWED_INVESTMENT_TYPES = {
    "Gold & Jewellery",
    "Gold Saving Schemes",
    "Chit Funds/Kuri",
    "Chit Funds / Kuri",
    "FD",
    "RD",
    "Insurance",
}


class InvestmentBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255, description="Investment name")
    type: str = Field(..., description="Investment category type")
    monthly_contribution: Decimal = Field(Decimal("0.00"), ge=0, description="Monthly contribution amount")
    total_paid: Decimal = Field(Decimal("0.00"), ge=0, description="Total amount paid so far")
    total_installments: int = Field(0, ge=0, description="Total number of installments")
    installments_paid: int = Field(0, ge=0, description="Number of installments paid")
    start_date: Optional[date] = Field(None, description="Investment start date")
    next_due: Optional[date] = Field(None, description="Next installment due date")
    next_due_date: Optional[date] = Field(None, description="Alias for next_due date")
    maturity_date: Optional[date] = Field(None, description="Investment maturity date")
    notes: Optional[str] = Field(None, max_length=2000, description="Notes")

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        if v not in ALLOWED_INVESTMENT_TYPES:
            raise ValueError(
                f"Invalid investment type '{v}'. Allowed types: {', '.join(sorted(ALLOWED_INVESTMENT_TYPES))}"
            )
        return v

    @model_validator(mode="after")
    def validate_installment_counts_and_dates(self) -> "InvestmentBase":
        # Synchronize next_due and next_due_date
        if self.next_due_date is not None and self.next_due is None:
            self.next_due = self.next_due_date
        elif self.next_due is not None and self.next_due_date is None:
            self.next_due_date = self.next_due

        if self.total_installments > 0 and self.installments_paid > self.total_installments:
            raise ValueError(
                f"installments_paid ({self.installments_paid}) cannot exceed total_installments ({self.total_installments})."
            )

        if self.start_date and self.maturity_date and self.maturity_date < self.start_date:
            raise ValueError(
                f"maturity_date ({self.maturity_date}) cannot be earlier than start_date ({self.start_date})."
            )

        return self


class InvestmentCreate(InvestmentBase):
    """Schema for creating a new investment."""
    pass


class InvestmentUpdate(BaseModel):
    """Schema for updating an existing investment. All fields optional."""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    type: Optional[str] = None
    monthly_contribution: Optional[Decimal] = Field(None, ge=0)
    total_paid: Optional[Decimal] = Field(None, ge=0)
    total_installments: Optional[int] = Field(None, ge=0)
    installments_paid: Optional[int] = Field(None, ge=0)
    start_date: Optional[date] = None
    next_due: Optional[date] = None
    next_due_date: Optional[date] = None
    maturity_date: Optional[date] = None
    notes: Optional[str] = Field(None, max_length=2000)

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ALLOWED_INVESTMENT_TYPES:
            raise ValueError(
                f"Invalid investment type '{v}'. Allowed types: {', '.join(sorted(ALLOWED_INVESTMENT_TYPES))}"
            )
        return v

    @model_validator(mode="after")
    def validate_installment_counts_and_dates(self) -> "InvestmentUpdate":
        if self.next_due_date is not None and self.next_due is None:
            self.next_due = self.next_due_date
        elif self.next_due is not None and self.next_due_date is None:
            self.next_due_date = self.next_due

        if (
            self.total_installments is not None
            and self.installments_paid is not None
            and self.total_installments > 0
            and self.installments_paid > self.total_installments
        ):
            raise ValueError(
                f"installments_paid ({self.installments_paid}) cannot exceed total_installments ({self.total_installments})."
            )

        if (
            self.start_date
            and self.maturity_date
            and self.maturity_date < self.start_date
        ):
            raise ValueError(
                f"maturity_date ({self.maturity_date}) cannot be earlier than start_date ({self.start_date})."
            )

        return self


class InvestmentResponse(BaseModel):
    """Schema for returning investment details with derived status and progress."""
    id: uuid.UUID
    name: str
    type: str
    monthly_contribution: Decimal
    total_paid: Decimal
    total_installments: int
    installments_paid: int
    start_date: Optional[date] = None
    next_due: Optional[date] = None
    next_due_date: Optional[date] = None
    maturity_date: Optional[date] = None
    notes: Optional[str] = None
    status: str = Field(..., description="Derived status: On Track, Due Soon, Overdue, Completed")
    progress_percentage: float = Field(..., description="Derived installment progress (0.0 to 100.0)")
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class InvestmentSummaryResponse(BaseModel):
    """Schema for investment portfolio summary."""
    total_invested: Decimal
    total_monthly_contribution: Decimal
    active_count: int
    completed_count: int
    overdue_count: int
    due_soon_count: int
