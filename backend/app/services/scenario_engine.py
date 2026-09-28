import copy
from datetime import date, timedelta
from decimal import Decimal, ROUND_CEILING
from typing import List, Optional, Dict, Any
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.financial_goal import FinancialGoal
from app.models.user import User
from app.schemas.financial_intelligence import (
    CashFlowSummary,
    ConflictReport,
    FinancialScenario,
    GoalChangeDetail,
)
from app.services.cash_flow_engine import calculate_user_cash_flow
from app.services.goal_feasibility_engine import evaluate_goal_feasibility, calculate_months_remaining
from app.services.conflict_detection_engine import analyze_multi_goal_conflict


def add_months_to_date(d: date, months: int) -> date:
    """Helper to extend date by given number of months cleanly."""
    new_year = d.year + (d.month + months - 1) // 12
    new_month = (d.month + months - 1) % 12 + 1
    # Handle day overflow (e.g. Feb 30 -> Feb 28)
    max_days = 31
    if new_month in [4, 6, 9, 11]:
        max_days = 30
    elif new_month == 2:
        is_leap = (new_year % 4 == 0 and (new_year % 100 != 0 or new_year % 400 == 0))
        max_days = 29 if is_leap else 28

    return date(new_year, new_month, min(d.day, max_days))


def evaluate_candidate_scenario(
    scenario_id: str,
    name: str,
    description: str,
    modified_goals: List[FinancialGoal],
    changes: List[GoalChangeDetail],
    tradeoffs: List[str],
    cash_flow: CashFlowSummary,
    today: Optional[date] = None,
) -> FinancialScenario:
    """Evaluates a modified goal configuration deterministically."""
    if today is None:
        today = date.today()

    active_goals = [g for g in modified_goals if g.is_active]
    evaluated = [evaluate_goal_feasibility(g, today=today) for g in active_goals]

    total_req = sum((e.required_monthly_contribution for e in evaluated), Decimal("0.00"))
    cap = cash_flow.available_capacity

    surplus_or_gap = cap - total_req
    is_feasible = (total_req <= cap) and all(e.is_feasible for e in evaluated)

    affected_names = [c.goal_name for c in changes]

    return FinancialScenario(
        id=scenario_id,
        name=name,
        description=description,
        changes=changes,
        is_feasible=is_feasible,
        monthly_requirement=total_req,
        monthly_capacity=cap,
        monthly_surplus_or_gap=surplus_or_gap,
        affected_goals=affected_names,
        tradeoffs=tradeoffs,
    )


def generate_financial_scenarios(
    db: Session,
    current_user: User,
    goals: List[FinancialGoal],
    cash_flow: CashFlowSummary,
    conflict: ConflictReport,
    today: Optional[date] = None,
) -> List[FinancialScenario]:
    """
    Scenario Generation Engine.
    Generates candidate trade-offs, evaluates them deterministically,
    filters duplicates/infeasible ones, and returns ~5 diverse trade-off scenarios.
    """
    if today is None:
        today = date.today()

    scenarios: List[FinancialScenario] = []
    active_goals = [g for g in goals if g.is_active]
    if not active_goals:
        return scenarios

    # Find high-pressure goal (highest target or shortfall)
    sorted_by_target = sorted(active_goals, key=lambda g: g.target_amount, reverse=True)
    primary_goal = sorted_by_target[0]

    # Scenario 1: Extend Deadline for primary goal
    g1_list = copy.deepcopy(goals)
    for g in g1_list:
        if g.id == primary_goal.id:
            orig_d = g.deadline
            new_d = add_months_to_date(g.deadline, 24)
            rem = max(Decimal("0.00"), g.target_amount - g.current_amount)
            m_left = calculate_months_remaining(new_d, today=today)
            g.deadline = new_d
            if m_left > 0:
                g.monthly_contribution = (rem / Decimal(str(m_left))).quantize(Decimal("0.01"), rounding=ROUND_CEILING)

            c1 = GoalChangeDetail(
                goal_id=g.id,
                goal_name=g.name,
                action_type="EXTEND_DEADLINE",
                original_target=g.target_amount,
                new_target=g.target_amount,
                original_deadline=orig_d,
                new_deadline=new_d,
                original_contribution=primary_goal.monthly_contribution,
                new_contribution=g.monthly_contribution,
            )
            scenarios.append(
                evaluate_candidate_scenario(
                    scenario_id="scenario_extend_deadline",
                    name=f"Extend {g.name} Timeline",
                    description=f"Extends the target date for '{g.name}' by 24 months to lower required monthly savings.",
                    modified_goals=g1_list,
                    changes=[c1],
                    tradeoffs=[f"Extends completion date for '{g.name}' from {orig_d.year} to {new_d.year}."],
                    cash_flow=cash_flow,
                    today=today,
                )
            )

    # Scenario 2: Reduce Target for primary goal by 15%
    g2_list = copy.deepcopy(goals)
    for g in g2_list:
        if g.id == primary_goal.id:
            orig_t = g.target_amount
            new_t = (g.target_amount * Decimal("0.85")).quantize(Decimal("0.01"))
            rem = max(Decimal("0.00"), new_t - g.current_amount)
            m_left = calculate_months_remaining(g.deadline, today=today)
            g.target_amount = new_t
            if m_left > 0:
                g.monthly_contribution = (rem / Decimal(str(m_left))).quantize(Decimal("0.01"), rounding=ROUND_CEILING)

            c2 = GoalChangeDetail(
                goal_id=g.id,
                goal_name=g.name,
                action_type="REDUCE_TARGET",
                original_target=orig_t,
                new_target=new_t,
                original_deadline=g.deadline,
                new_deadline=g.deadline,
                original_contribution=primary_goal.monthly_contribution,
                new_contribution=g.monthly_contribution,
            )
            scenarios.append(
                evaluate_candidate_scenario(
                    scenario_id="scenario_reduce_target",
                    name=f"Optimize {g.name} Target",
                    description=f"Reduces target amount for '{g.name}' by 15% to align with monthly capacity.",
                    modified_goals=g2_list,
                    changes=[c2],
                    tradeoffs=[f"Reduces final target amount from ₹{orig_t:,.0f} to ₹{new_t:,.0f}."],
                    cash_flow=cash_flow,
                    today=today,
                )
            )

    # Scenario 3: Increase Monthly Savings Capacity by ₹5,000
    increased_cf = CashFlowSummary(
        monthly_income=cash_flow.monthly_income + Decimal("5000.00"),
        monthly_expenses=cash_flow.monthly_expenses,
        existing_commitments=cash_flow.existing_commitments,
        available_capacity=cash_flow.available_capacity + Decimal("5000.00"),
        total_goal_contributions=cash_flow.total_goal_contributions,
        remaining_goal_capacity=cash_flow.remaining_goal_capacity + Decimal("5000.00"),
    )
    g3_list = copy.deepcopy(goals)
    changes3 = []
    for g in g3_list:
        rem = max(Decimal("0.00"), g.target_amount - g.current_amount)
        m_left = calculate_months_remaining(g.deadline, today=today)
        if m_left > 0:
            new_c = (rem / Decimal(str(m_left))).quantize(Decimal("0.01"), rounding=ROUND_CEILING)
            if new_c != g.monthly_contribution:
                changes3.append(
                    GoalChangeDetail(
                        goal_id=g.id,
                        goal_name=g.name,
                        action_type="INCREASE_CONTRIBUTION",
                        original_target=g.target_amount,
                        new_target=g.target_amount,
                        original_deadline=g.deadline,
                        new_deadline=g.deadline,
                        original_contribution=g.monthly_contribution,
                        new_contribution=new_c,
                    )
                )
                g.monthly_contribution = new_c

    scenarios.append(
        evaluate_candidate_scenario(
            scenario_id="scenario_increase_savings",
            name="Increase Monthly Capacity (+₹5,000)",
            description="Increases monthly savings allocation by ₹5,000/month through expense optimization.",
            modified_goals=g3_list,
            changes=changes3,
            tradeoffs=["Requires reducing monthly essential expenses or adding extra income by ₹5,000."],
            cash_flow=increased_cf,
            today=today,
        )
    )

    # Scenario 4: Balanced Reallocation across all goals
    g4_list = copy.deepcopy(goals)
    changes4 = []
    for g in g4_list:
        rem = max(Decimal("0.00"), g.target_amount - g.current_amount)
        m_left = calculate_months_remaining(g.deadline, today=today)
        if m_left > 0:
            new_c = (rem / Decimal(str(m_left))).quantize(Decimal("0.01"), rounding=ROUND_CEILING)
            if new_c != g.monthly_contribution:
                changes4.append(
                    GoalChangeDetail(
                        goal_id=g.id,
                        goal_name=g.name,
                        action_type="INCREASE_CONTRIBUTION" if new_c > g.monthly_contribution else "DECREASE_CONTRIBUTION",
                        original_target=g.target_amount,
                        new_target=g.target_amount,
                        original_deadline=g.deadline,
                        new_deadline=g.deadline,
                        original_contribution=g.monthly_contribution,
                        new_contribution=new_c,
                    )
                )
                g.monthly_contribution = new_c

    scenarios.append(
        evaluate_candidate_scenario(
            scenario_id="scenario_balanced_reallocation",
            name="Exact Mathematical Reallocation",
            description="Reallocates monthly contributions strictly based on exact mathematical required rates.",
            modified_goals=g4_list,
            changes=changes4,
            tradeoffs=["Adjusts monthly contributions across multiple goals simultaneously."],
            cash_flow=cash_flow,
            today=today,
        )
    )

    # Scenario 5: Combination (Extend timeline + 10% target reduction)
    g5_list = copy.deepcopy(goals)
    changes5 = []
    for g in g5_list:
        if g.id == primary_goal.id:
            orig_d = g.deadline
            orig_t = g.target_amount
            new_d = add_months_to_date(g.deadline, 12)
            new_t = (g.target_amount * Decimal("0.90")).quantize(Decimal("0.01"))
            g.deadline = new_d
            g.target_amount = new_t

            rem = max(Decimal("0.00"), new_t - g.current_amount)
            m_left = calculate_months_remaining(new_d, today=today)
            if m_left > 0:
                g.monthly_contribution = (rem / Decimal(str(m_left))).quantize(Decimal("0.01"), rounding=ROUND_CEILING)

            changes5.append(
                GoalChangeDetail(
                    goal_id=g.id,
                    goal_name=g.name,
                    action_type="EXTEND_DEADLINE",
                    original_target=orig_t,
                    new_target=new_t,
                    original_deadline=orig_d,
                    new_deadline=new_d,
                    original_contribution=primary_goal.monthly_contribution,
                    new_contribution=g.monthly_contribution,
                )
            )

    scenarios.append(
        evaluate_candidate_scenario(
            scenario_id="scenario_hybrid_plan",
            name="Balanced Hybrid Plan",
            description=f"Extends timeline by 12 months and optimizes target amount by 10% for '{primary_goal.name}'.",
            modified_goals=g5_list,
            changes=changes5,
            tradeoffs=[f"Extends deadline by 1 year and reduces target by 10% for '{primary_goal.name}'."],
            cash_flow=cash_flow,
            today=today,
        )
    )

    # Filter out infeasible ones if feasible ones exist, or keep best feasible trade-offs
    feasible_scenarios = [s for s in scenarios if s.is_feasible]
    if len(feasible_scenarios) >= 3:
        return feasible_scenarios[:5]

    return scenarios[:5]


def apply_scenario(
    db: Session,
    current_user: User,
    scenario_id: str,
    today: Optional[date] = None,
) -> bool:
    """
    Applies a verified scenario to PostgreSQL financial goals upon explicit user action.
    """
    if today is None:
        today = date.today()

    goal_stmt = select(FinancialGoal).where(FinancialGoal.user_id == current_user.id)
    goals = list(db.scalars(goal_stmt).all())
    cash_flow = calculate_user_cash_flow(db, current_user, goals=goals)
    conflict = analyze_multi_goal_conflict(goals, cash_flow, today=today)

    generated = generate_financial_scenarios(db, current_user, goals, cash_flow, conflict, today=today)
    target_scenario = next((s for s in generated if s.id == scenario_id), None)
    if not target_scenario:
        return False

    for change in target_scenario.changes:
        g = next((g for g in goals if g.id == change.goal_id), None)
        if g:
            g.target_amount = change.new_target
            g.deadline = change.new_deadline
            g.monthly_contribution = change.new_contribution

    db.commit()
    return True
