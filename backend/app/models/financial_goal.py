import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import List, Optional, TYPE_CHECKING
from sqlalchemy import String, Date, DateTime, Boolean, Numeric, ForeignKey, CheckConstraint, Index, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.user import User
    from app.models.goal_scenario_change import GoalScenarioChange


class FinancialGoal(Base):
    """
    Financial Goal Model.
    Stores user's target financial goals.
    """
    __tablename__ = "financial_goals"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    category: Mapped[str] = mapped_column(String(50), nullable=False, default="Other")
    target_amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    current_amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False, default=Decimal("0.00"))
    deadline: Mapped[date] = mapped_column(Date, nullable=False)
    monthly_contribution: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False, default=Decimal("0.00"))
    priority: Mapped[str] = mapped_column(String(20), nullable=False, default="Medium")
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="financial_goals")
    scenario_changes: Mapped[List["GoalScenarioChange"]] = relationship(
        "GoalScenarioChange", back_populates="goal", cascade="all, delete-orphan"
    )

    __table_args__ = (
        CheckConstraint("target_amount >= 0", name="ck_financial_goal_target_amount_non_negative"),
        CheckConstraint("current_amount >= 0", name="ck_financial_goal_current_amount_non_negative"),
        CheckConstraint("monthly_contribution >= 0", name="ck_financial_goal_monthly_contribution_non_negative"),
        CheckConstraint("priority IN ('Low', 'Medium', 'High', 'Critical')", name="ck_financial_goal_priority_valid"),
        Index("ix_financial_goals_user_id", "user_id"),
    )
