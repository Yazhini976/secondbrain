import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

ALLOWED_GOAL_CATEGORIES = {
    "Emergency Fund",
    "Education",
    "Home",
    "Vehicle",
    "Retirement",
    "Investment",
    "Travel",
    "Other",
}

ALLOWED_GOAL_PRIORITIES = {"Low", "Medium", "High", "Critical"}


class FinancialGoalBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255, description="Goal name")
    category: str = Field("Other", description="Goal category")
    target_amount: Decimal = Field(..., ge=0, description="Target financial goal amount")
    current_amount: Decimal = Field(Decimal("0.00"), ge=0, description="Currently saved amount")
    monthly_contribution: Decimal = Field(Decimal("0.00"), ge=0, description="Current monthly contribution")
    deadline: date = Field(..., description="Target completion date")
    priority: str = Field("Medium", description="Goal priority level")
    is_active: bool = Field(True, description="Whether the goal is active in financial calculations")

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: str) -> str:
        if v not in ALLOWED_GOAL_CATEGORIES:
            # Fall back to 'Other' if unknown
            return "Other"
        return v

    @field_validator("priority")
    @classmethod
    def validate_priority(cls, v: str) -> str:
        if v not in ALLOWED_GOAL_PRIORITIES:
            raise ValueError(
                f"Invalid priority '{v}'. Allowed: {', '.join(sorted(ALLOWED_GOAL_PRIORITIES))}"
            )
        return v


class FinancialGoalCreate(FinancialGoalBase):
    target_date: Optional[date] = Field(None, description="Alias for deadline")

    @model_validator(mode="after")
    def sync_target_date(self) -> "FinancialGoalCreate":
        if self.target_date and not self.deadline:
            self.deadline = self.target_date
        return self


class FinancialGoalUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    category: Optional[str] = None
    target_amount: Optional[Decimal] = Field(None, ge=0)
    current_amount: Optional[Decimal] = Field(None, ge=0)
    monthly_contribution: Optional[Decimal] = Field(None, ge=0)
    deadline: Optional[date] = None
    target_date: Optional[date] = None
    priority: Optional[str] = None
    is_active: Optional[bool] = None

    @field_validator("priority")
    @classmethod
    def validate_priority(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ALLOWED_GOAL_PRIORITIES:
            raise ValueError(
                f"Invalid priority '{v}'. Allowed: {', '.join(sorted(ALLOWED_GOAL_PRIORITIES))}"
            )
        return v

    @model_validator(mode="after")
    def sync_target_date(self) -> "FinancialGoalUpdate":
        if self.target_date and not self.deadline:
            self.deadline = self.target_date
        return self


class FinancialGoalResponse(BaseModel):
    id: uuid.UUID
    name: str
    category: str
    target_amount: Decimal
    current_amount: Decimal
    monthly_contribution: Decimal
    deadline: date
    target_date: date
    priority: str
    is_active: bool
    remaining_amount: Decimal
    required_monthly_contribution: Decimal
    contribution_gap: Decimal
    months_remaining: int
    is_feasible: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
