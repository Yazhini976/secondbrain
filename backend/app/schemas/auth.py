import uuid
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, EmailStr, Field

from app.schemas.user import UserResponse


class SignUpRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, description="User full name")
    email: str = Field(..., description="Valid email address")
    phone: str = Field(..., min_length=7, max_length=20, description="Phone number")
    password: str = Field(..., min_length=4, max_length=128, description="Account password")
    monthly_income: Optional[Decimal] = Field(default=Decimal("75000.00"), description="Monthly income baseline")


class LoginRequest(BaseModel):
    username: Optional[str] = Field(None, description="Email address or Phone number")
    identifier: Optional[str] = Field(None, description="Alternative field for username")
    password: str = Field(..., description="Account password")

    @property
    def login_identifier(self) -> str:
        return (self.username or self.identifier or "").strip()


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class FinancialProfileUpdate(BaseModel):
    monthly_income: Optional[Decimal] = Field(None, ge=Decimal("0.00"), description="Monthly income")
    monthly_capacity: Optional[Decimal] = Field(None, ge=Decimal("0.00"), description="Monthly financial capacity")
