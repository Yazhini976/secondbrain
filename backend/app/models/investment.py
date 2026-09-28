import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional, TYPE_CHECKING
from sqlalchemy import String, Text, Date, DateTime, Numeric, Integer, ForeignKey, CheckConstraint, Index, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.user import User


class Investment(Base):
    """
    Investment Model.
    Stores investment portfolio facts per user.
    
    IMPORTANT Architectural Rule:
    Investment status (On Track, Due Soon, Overdue, Completed) is DERIVED
    in the domain/Python layer from facts. It is NOT stored as a database column.
    """
    __tablename__ = "investments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    type: Mapped[str] = mapped_column(String(100), nullable=False)
    monthly_contribution: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False, default=Decimal("0.00"))
    total_paid: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False, default=Decimal("0.00"))
    total_installments: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    installments_paid: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    start_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    next_due: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    maturity_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="investments")

    __table_args__ = (
        CheckConstraint("monthly_contribution >= 0", name="ck_investment_monthly_contribution_non_negative"),
        CheckConstraint("total_paid >= 0", name="ck_investment_total_paid_non_negative"),
        CheckConstraint("total_installments >= 0", name="ck_investment_total_installments_non_negative"),
        CheckConstraint("installments_paid >= 0", name="ck_investment_installments_paid_non_negative"),
        CheckConstraint("installments_paid <= total_installments", name="ck_investment_installments_paid_lte_total"),
        Index("ix_investments_user_next_due", "user_id", "next_due"),
        Index("ix_investments_user_maturity_date", "user_id", "maturity_date"),
    )
