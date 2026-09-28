import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, ConfigDict


class UserResponse(BaseModel):
    """
    Public User Profile Response Schema.
    Does NOT leak private credentials or token internals.
    """
    id: uuid.UUID
    external_auth_id: str
    email: Optional[str] = None
    phone: Optional[str] = None
    display_name: Optional[str] = None
    monthly_income: Optional[Decimal] = None
    monthly_capacity: Optional[Decimal] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
