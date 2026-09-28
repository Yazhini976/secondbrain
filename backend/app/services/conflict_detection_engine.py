from decimal import Decimal
from typing import List, Optional
from datetime import date

from app.models.financial_goal import FinancialGoal
from app.schemas.financial_intelligence import CashFlowSummary, ConflictReport
from app.services.goal_feasibility_engine import evaluate_goal_feasibility


def analyze_multi_goal_conflict(
    goals: List[FinancialGoal],
    cash_flow: CashFlowSummary,
    today: Optional[date] = None,
) -> ConflictReport:
    """
    Deterministic Multi-Goal Conflict Engine.
    Analyzes all active goals together against available monthly capacity.
    """
    if today is None:
        today = date.today()

    active_goals = [g for g in goals if g.is_active]
    evaluated = [evaluate_goal_feasibility(g, today=today) for g in active_goals]

    available_cap = cash_flow.available_capacity
    total_required = sum((e.required_monthly_contribution for e in evaluated), Decimal("0.00"))

    affected_ids = []
    affected_names = []
    reasons = []

    # Check for individual goal deadline failures / infeasibility
    infeasible_goals = [e for e in evaluated if not e.is_feasible]
    if infeasible_goals:
        for eg in infeasible_goals:
            affected_ids.append(eg.id)
            affected_names.append(eg.name)
            if eg.months_remaining == 0 and eg.remaining_amount > Decimal("0.00"):
                reasons.append(f"Goal '{eg.name}' deadline has passed or has 0 months remaining.")
            else:
                reasons.append(f"Goal '{eg.name}' current contribution (₹{eg.monthly_contribution:,.0f}) is below required (₹{eg.required_monthly_contribution:,.0f}).")

    if total_required > available_cap:
        shortfall = total_required - available_cap
        for e in evaluated:
            if e.id not in affected_ids:
                affected_ids.append(e.id)
                affected_names.append(e.name)
        
        reasons.append(
            f"Total required monthly contributions (₹{total_required:,.0f}) exceed available monthly capacity (₹{available_cap:,.0f}) by ₹{shortfall:,.0f}/month."
        )
        return ConflictReport(
            has_conflict=True,
            monthly_capacity=available_cap,
            total_required_contribution=total_required,
            monthly_shortfall=shortfall,
            affected_goal_ids=affected_ids,
            affected_goal_names=affected_names,
            conflict_reason="; ".join(reasons),
        )

    if infeasible_goals:
        shortfall = sum((e.contribution_gap for e in infeasible_goals), Decimal("0.00"))
        return ConflictReport(
            has_conflict=True,
            monthly_capacity=available_cap,
            total_required_contribution=total_required,
            monthly_shortfall=shortfall,
            affected_goal_ids=affected_ids,
            affected_goal_names=affected_names,
            conflict_reason="; ".join(reasons),
        )

    return ConflictReport(
        has_conflict=False,
        monthly_capacity=available_cap,
        total_required_contribution=total_required,
        monthly_shortfall=Decimal("0.00"),
        affected_goal_ids=[],
        affected_goal_names=[],
        conflict_reason="All active goals are mathematically feasible within your available monthly capacity.",
    )
