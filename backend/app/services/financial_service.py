
import uuid
from datetime import date
from decimal import Decimal
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.financial_goal import FinancialGoal
from app.schemas.financial_goal import (
    FinancialGoalCreate,
    FinancialGoalUpdate,
    FinancialGoalResponse,
)
from app.services.goal_feasibility_engine import evaluate_goal_feasibility
from app.services.cash_flow_engine import calculate_user_cash_flow


def _get_available_capacity(db: Session, current_user: User) -> Decimal:
    """Computes the user's real monthly cash-flow capacity from DB."""
    cash_flow = calculate_user_cash_flow(db, current_user)
    return cash_flow.available_capacity


def create_financial_goal(
    db: Session,
    current_user: User,
    goal_in: FinancialGoalCreate,
    today: Optional[date] = None,
) -> FinancialGoalResponse:
    """Creates a new financial goal scoped to current_user."""
    deadline_val = goal_in.deadline or goal_in.target_date
    if not deadline_val:
        deadline_val = date.today()

    goal = FinancialGoal(
        user_id=current_user.id,
        name=goal_in.name.strip(),
        category=goal_in.category,
        target_amount=goal_in.target_amount,
        current_amount=goal_in.current_amount,
        monthly_contribution=goal_in.monthly_contribution,
        deadline=deadline_val,
        priority=goal_in.priority,
        is_active=goal_in.is_active,
    )
    db.add(goal)
    db.commit()
    db.refresh(goal)
    capacity = _get_available_capacity(db, current_user)
    return evaluate_goal_feasibility(goal, today=today, available_capacity=capacity)


def get_financial_goal(
    db: Session,
    current_user: User,
    goal_id: uuid.UUID,
    today: Optional[date] = None,
) -> Optional[FinancialGoalResponse]:
    """Retrieves a financial goal by ID scoped to current_user."""
    stmt = select(FinancialGoal).where(
        FinancialGoal.id == goal_id,
        FinancialGoal.user_id == current_user.id,
    )
    goal = db.scalars(stmt).first()
    if not goal:
        return None
    capacity = _get_available_capacity(db, current_user)
    return evaluate_goal_feasibility(goal, today=today, available_capacity=capacity)


def get_financial_goal_orm(
    db: Session,
    current_user: User,
    goal_id: uuid.UUID,
) -> Optional[FinancialGoal]:
    """Helper to retrieve raw ORM model scoped to current_user."""
    stmt = select(FinancialGoal).where(
        FinancialGoal.id == goal_id,
        FinancialGoal.user_id == current_user.id,
    )
    return db.scalars(stmt).first()


def list_financial_goals(
    db: Session,
    current_user: User,
    today: Optional[date] = None,
) -> List[FinancialGoalResponse]:
    """Lists financial goals belonging to current_user, capacity-aware."""
    stmt = select(FinancialGoal).where(
        FinancialGoal.user_id == current_user.id
    ).order_by(FinancialGoal.deadline.asc(), FinancialGoal.created_at.desc())

    goals = list(db.scalars(stmt).all())
    # Compute capacity once for all goals
    capacity = _get_available_capacity(db, current_user)
    return [evaluate_goal_feasibility(g, today=today, available_capacity=capacity) for g in goals]


def update_financial_goal(
    db: Session,
    current_user: User,
    goal_id: uuid.UUID,
    goal_in: FinancialGoalUpdate,
    today: Optional[date] = None,
) -> Optional[FinancialGoalResponse]:
    """Updates a financial goal belonging to current_user."""
    goal = get_financial_goal_orm(db, current_user, goal_id)
    if not goal:
        return None

    if goal_in.name is not None:
        goal.name = goal_in.name.strip()
    if goal_in.category is not None:
        goal.category = goal_in.category
    if goal_in.target_amount is not None:
        goal.target_amount = goal_in.target_amount
    if goal_in.current_amount is not None:
        goal.current_amount = goal_in.current_amount
    if goal_in.monthly_contribution is not None:
        goal.monthly_contribution = goal_in.monthly_contribution
    if goal_in.deadline is not None or goal_in.target_date is not None:
        goal.deadline = goal_in.deadline or goal_in.target_date
    if goal_in.priority is not None:
        goal.priority = goal_in.priority
    if goal_in.is_active is not None:
        goal.is_active = goal_in.is_active

    db.commit()
    db.refresh(goal)
    capacity = _get_available_capacity(db, current_user)
    return evaluate_goal_feasibility(goal, today=today, available_capacity=capacity)


def delete_financial_goal(
    db: Session,
    current_user: User,
    goal_id: uuid.UUID,
) -> bool:
    """Deletes a financial goal belonging to current_user."""
    goal = get_financial_goal_orm(db, current_user, goal_id)
    if not goal:
        return False
    db.delete(goal)
    db.commit()
    return True
