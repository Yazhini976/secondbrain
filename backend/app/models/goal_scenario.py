import uuid
from datetime import datetime
from typing import List, Optional, Any, TYPE_CHECKING
from sqlalchemy import String, Text, DateTime, ForeignKey, Index, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.user import User
    from app.models.goal_scenario_change import GoalScenarioChange


class GoalScenario(Base):
    """
    Goal Scenario Model.
    Represents what-if financial optimization scenarios.
    Payloads and engine outputs use JSONB for flexible payload storage.
    """
    __tablename__ = "goal_scenarios"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(50), nullable=False, default="draft")
    base_plan_reference: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    scenario_payload: Mapped[Optional[Any]] = mapped_column(JSONB, nullable=True)
    feasibility_result: Mapped[Optional[Any]] = mapped_column(JSONB, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="goal_scenarios")
    changes: Mapped[List["GoalScenarioChange"]] = relationship(
        "GoalScenarioChange", back_populates="scenario", cascade="all, delete-orphan"
    )

    __table_args__ = (
        Index("ix_goal_scenarios_user_id", "user_id"),
    )
