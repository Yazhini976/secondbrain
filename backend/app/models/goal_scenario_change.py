import uuid
from datetime import datetime
from typing import Optional, Any, TYPE_CHECKING
from sqlalchemy import String, DateTime, ForeignKey, CheckConstraint, Index, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.goal_scenario import GoalScenario
    from app.models.financial_goal import FinancialGoal


class GoalScenarioChange(Base):
    """
    Goal Scenario Change Model.
    Tracks individual goal modifications contained within a goal scenario.
    """
    __tablename__ = "goal_scenario_changes"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    scenario_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("goal_scenarios.id", ondelete="CASCADE"), nullable=False, index=True)
    goal_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("financial_goals.id", ondelete="CASCADE"), nullable=False, index=True)
    operation: Mapped[str] = mapped_column(String(50), nullable=False)
    old_value: Mapped[Optional[Any]] = mapped_column(JSONB, nullable=True)
    new_value: Mapped[Optional[Any]] = mapped_column(JSONB, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    scenario: Mapped["GoalScenario"] = relationship("GoalScenario", back_populates="changes")
    goal: Mapped["FinancialGoal"] = relationship("FinancialGoal", back_populates="scenario_changes")

    __table_args__ = (
        CheckConstraint(
            "operation IN ('KEEP_TARGET', 'REDUCE_TARGET', 'EXTEND_DEADLINE', 'INCREASE_CONTRIBUTION', 'DECREASE_CONTRIBUTION', 'PAUSE_CONTRIBUTION')",
            name="ck_goal_scenario_change_operation_valid"
        ),
        Index("ix_goal_scenario_changes_scenario_id", "scenario_id"),
    )
