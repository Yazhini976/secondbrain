from decimal import Decimal
from typing import List, Optional
from sqlalchemy import select, extract, func
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.expense import Expense
from app.models.investment import Investment
from app.models.financial_goal import FinancialGoal
from app.schemas.financial_intelligence import CashFlowSummary

DEFAULT_MONTHLY_INCOME = Decimal("250000.00")
DEFAULT_MONTHLY_EXPENSES = Decimal("25000.00")
DEFAULT_EXISTING_COMMITMENTS = Decimal("10000.00")


def calculate_user_cash_flow(
    db: Session,
    current_user: User,
    goals: Optional[List[FinancialGoal]] = None,
    custom_income: Optional[Decimal] = None,
) -> CashFlowSummary:
    """
    Deterministic Cash Flow Engine.
    
    Formula:
    available_capacity = user.monthly_capacity (from DB) OR (monthly_income - monthly_expenses - existing_commitments)
    remaining_goal_capacity = available_capacity - total_goal_contributions
    """
    monthly_income = custom_income or getattr(current_user, "monthly_income", None) or DEFAULT_MONTHLY_INCOME

    # Calculate actual monthly expenses from DB if expenses exist, otherwise fallback
    expense_stmt = select(func.coalesce(func.sum(Expense.amount), 0)).where(
        Expense.user_id == current_user.id
    )
    db_expenses_sum = Decimal(str(db.scalar(expense_stmt) or 0))
    monthly_expenses = db_expenses_sum if db_expenses_sum > Decimal("0.00") else DEFAULT_MONTHLY_EXPENSES

    # Calculate actual monthly investment commitments from DB if investments exist, otherwise fallback
    inv_stmt = select(func.coalesce(func.sum(Investment.monthly_contribution), 0)).where(
        Investment.user_id == current_user.id
    )
    db_inv_sum = Decimal(str(db.scalar(inv_stmt) or 0))
    existing_commitments = db_inv_sum if db_inv_sum > Decimal("0.00") else DEFAULT_EXISTING_COMMITMENTS

    # Available monthly financial capacity (prefer user-configured DB capacity)
    user_cap = getattr(current_user, "monthly_capacity", None)
    if user_cap is not None and user_cap > Decimal("0.00"):
        available_capacity = Decimal(str(user_cap))
    else:
        available_capacity = max(Decimal("0.00"), monthly_income - monthly_expenses - existing_commitments)

    # Fetch active goals if not provided
    if goals is None:
        goal_stmt = select(FinancialGoal).where(
            FinancialGoal.user_id == current_user.id,
            FinancialGoal.is_active == True,
        )
        goals = list(db.scalars(goal_stmt).all())

    total_goal_contributions = sum((g.monthly_contribution for g in goals if g.is_active), Decimal("0.00"))
    remaining_goal_capacity = available_capacity - total_goal_contributions

    return CashFlowSummary(
        monthly_income=monthly_income,
        monthly_expenses=monthly_expenses,
        existing_commitments=existing_commitments,
        available_capacity=available_capacity,
        total_goal_contributions=total_goal_contributions,
        remaining_goal_capacity=remaining_goal_capacity,
    )
