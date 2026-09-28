from datetime import date
from decimal import Decimal, ROUND_CEILING
from typing import Optional
from app.models.financial_goal import FinancialGoal
from app.schemas.financial_goal import FinancialGoalResponse


def calculate_months_remaining(deadline: date, today: Optional[date] = None) -> int:
    """Calculates remaining full calendar months between today and target deadline."""
    if today is None:
        today = date.today()

    if deadline < today:
        return 0

    year_diff = deadline.year - today.year
    month_diff = deadline.month - today.month
    day_diff = deadline.day - today.day

    total_months = year_diff * 12 + month_diff
    if day_diff < 0:
        total_months -= 1

    return max(0, total_months)


def evaluate_goal_feasibility(
    goal: FinancialGoal,
    today: Optional[date] = None,
    available_capacity: Optional[Decimal] = None,
) -> FinancialGoalResponse:
    """
    Evaluates individual financial goal feasibility deterministically.

    Two-gate feasibility check:
      Gate 1 — Cash Flow Gate: monthly_contribution must not exceed the user's
               available_capacity (income - expenses - other commitments).
               If it does, the goal is Infeasible regardless of deadline math.
      Gate 2 — Deadline Gate: monthly_contribution must cover the required
               contribution to hit the target by the deadline.
    Both gates must pass for is_feasible = True.
    """
    if today is None:
        today = date.today()

    target_amt = Decimal(str(goal.target_amount))
    curr_amt = Decimal(str(goal.current_amount))
    curr_contrib = Decimal(str(goal.monthly_contribution))

    remaining_amt = max(Decimal("0.00"), target_amt - curr_amt)
    months_left = calculate_months_remaining(goal.deadline, today=today)

    # ── Gate 1: Cash Flow Capacity Check ──────────────────────────────────────
    # If the user's contribution already exceeds what they can actually afford,
    # the goal is infeasible — no matter what deadline math says.
    exceeds_capacity = (
        available_capacity is not None
        and curr_contrib > available_capacity
    )

    # ── Gate 2: Deadline / Required Contribution Check ─────────────────────────
    if remaining_amt == Decimal("0.00"):
        req_contrib = Decimal("0.00")
        deadline_feasible = True
    elif months_left == 0:
        req_contrib = remaining_amt
        deadline_feasible = False
    else:
        raw_req = remaining_amt / Decimal(str(months_left))
        req_contrib = raw_req.quantize(Decimal("0.01"), rounding=ROUND_CEILING)
        deadline_feasible = curr_contrib >= req_contrib

    # ── Final Verdict ──────────────────────────────────────────────────────────
    is_feasible = deadline_feasible and not exceeds_capacity

    contrib_gap = max(Decimal("0.00"), req_contrib - curr_contrib)

    return FinancialGoalResponse(
        id=goal.id,
        name=goal.name,
        category=goal.category or "Other",
        target_amount=target_amt,
        current_amount=curr_amt,
        monthly_contribution=curr_contrib,
        deadline=goal.deadline,
        target_date=goal.deadline,
        priority=goal.priority,
        is_active=goal.is_active,
        remaining_amount=remaining_amt,
        required_monthly_contribution=req_contrib,
        contribution_gap=contrib_gap,
        months_remaining=months_left,
        is_feasible=is_feasible,
        created_at=goal.created_at,
        updated_at=goal.updated_at,
    )
