import os
import re
from datetime import date
from decimal import Decimal
from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.financial_goal import FinancialGoal
from app.models.expense import Expense
from app.models.investment import Investment
from app.schemas.financial_intelligence import (
    AIChatRequest,
    AIChatResponse,
    FinancialAnalysisResponse,
    FinancialScenario,
)
from app.services.cash_flow_engine import calculate_user_cash_flow
from app.services.goal_feasibility_engine import evaluate_goal_feasibility
from app.services.conflict_detection_engine import analyze_multi_goal_conflict
from app.services.scenario_engine import generate_financial_scenarios, apply_scenario


def get_full_financial_analysis(
    db: Session,
    current_user: User,
    today: Optional[date] = None,
) -> FinancialAnalysisResponse:
    """Helper to assemble full verified financial analysis from deterministic engines."""
    if today is None:
        today = date.today()

    goal_stmt = db.query(FinancialGoal).filter(
        FinancialGoal.user_id == current_user.id,
        FinancialGoal.is_active == True,
    )
    goals = list(goal_stmt.all())

    cash_flow = calculate_user_cash_flow(db, current_user, goals=goals)
    conflict = analyze_multi_goal_conflict(goals, cash_flow, today=today)
    scenarios = generate_financial_scenarios(db, current_user, goals, cash_flow, conflict, today=today)

    capacity = cash_flow.available_capacity
    evaluated_goals = [evaluate_goal_feasibility(g, today=today, available_capacity=capacity) for g in goals]
    overall_feasibility = not conflict.has_conflict

    return FinancialAnalysisResponse(
        cash_flow=cash_flow,
        goals=evaluated_goals,
        conflict=conflict,
        scenarios=scenarios,
        overall_feasibility=overall_feasibility,
    )


def extract_intent(user_message: str) -> str:
    """Extracts user intent deterministically from natural language question."""
    msg = user_message.lower().strip()

    # 1. Greetings
    if re.search(r"\b(hi|hello|hey|namaste|good morning|good afternoon|good evening)\b", msg):
        return "GREETING"

    # 2. Scenario Execution & Application
    if re.search(r"\b(confirm|yes apply|execute)\b", msg) or re.search(
        r"\b(apply|choose|select)\b.*(option|scenario|plan|\b\d+\b)", msg
    ):
        return "APPLY_SCENARIO"

    # 3. Actionable Conflict Advice
    if re.search(r"\b(what should i do|how (to|can i) (fix|solve|resolve)|give (me )?advice|recommendations?|suggestions?)\b", msg):
        return "ACTIONABLE_ADVICE"

    # 4. Income & Capacity
    if re.search(r"\b(income|salary|earn|capacity|budget|available budget)\b", msg):
        return "INCOME_CAPACITY"

    # 5. Expenses
    if re.search(r"\b(expenses?|spending|spent|outflow|costs?)\b", msg):
        return "EXPENSE_QUERY"

    # 6. Investments
    if re.search(r"\b(investments?|sips?|portfolio|mutual funds?|gold)\b", msg):
        return "INVESTMENT_QUERY"

    # 6. Conflict Analysis
    if re.search(r"\b(conflict|conflicting|problem|shortfall|gap|pressure|why (are )?(my )?goals?)\b", msg):
        return "ANALYZE_CONFLICT"

    # 7. Goals Listing
    if re.search(r"\b(my goals?|list goals?|all goals?|targets?|what are my goals)\b", msg):
        return "GOALS_QUERY"

    # 9. Scenarios & Alternatives
    if re.search(r"\b(alternative|alternatives|options?|scenarios?|plans?|different plan)\b", msg):
        return "GENERATE_SCENARIOS"

    # 10. Financial Impact (What if)
    if re.search(r"\b(increase|decrease|save more|save extra|what if|more money|extra income)\b", msg):
        return "ASK_FINANCIAL_IMPACT"

    # 11. General Feasibility
    if re.search(r"\b(afford|feasible|possible|reach|achieve|status|summary)\b", msg):
        return "ANALYZE_FINANCES"

    return "ANALYZE_FINANCES"


def process_ai_interaction(
    db: Session,
    current_user: User,
    request: AIChatRequest,
    today: Optional[date] = None,
) -> AIChatResponse:
    """
    Financial Intelligence AI Interaction Layer.
    Translates user questions into intent -> queries deterministic engines and database -> replies with clear facts.
    """
    if today is None:
        today = date.today()

    analysis = get_full_financial_analysis(db, current_user, today=today)
    intent = extract_intent(request.message)

    reply = ""
    suggested_actions: List[str] = []
    requires_confirmation = False
    pending_scenario_id = None

    user_name = current_user.display_name or "there"

    # ─────────────────────────────────────────────────────────────────────────────
    # 1. GREETING
    # ─────────────────────────────────────────────────────────────────────────────
    if intent == "GREETING":
        has_conflict = analysis.conflict.has_conflict
        status_line = (
            f"You currently have an active funding shortfall of ₹{analysis.conflict.monthly_shortfall:,.0f}/month."
            if has_conflict
            else "All your goals are currently in healthy financial balance!"
        )
        reply = (
            f"Hello {user_name}! I am your Second Brain Financial Intelligence Assistant.\n\n"
            f"{status_line}\n\n"
            f"I can help you analyze your cash flow, explore trade-off scenarios, check expenses, or optimize your goals. "
            f"What would you like to explore?"
        )
        suggested_actions = (
            ["Why are my goals conflicting?", "Explore Alternatives", "What should I do?"]
            if has_conflict
            else ["Can I afford all my goals?", "What are my goals?", "What if I save ₹5,000 more?"]
        )

    # ─────────────────────────────────────────────────────────────────────────────
    # 2. INCOME & CAPACITY
    # ─────────────────────────────────────────────────────────────────────────────
    elif intent == "INCOME_CAPACITY":
        income = current_user.monthly_income or Decimal("0.00")
        capacity = analysis.cash_flow.available_capacity
        req = analysis.conflict.total_required_contribution
        reply = (
            f"Here is your income and capacity breakdown:\n\n"
            f"• Monthly Income: ₹{income:,.0f}/month\n"
            f"• Configured Savings Capacity: ₹{capacity:,.0f}/month\n"
            f"• Total Required by Goals: ₹{req:,.0f}/month\n\n"
        )
        if analysis.conflict.has_conflict:
            reply += (
                f"Your goals currently exceed your available monthly capacity by "
                f"₹{analysis.conflict.monthly_shortfall:,.0f}/month. You can tap 'Edit' on the Goals screen "
                f"to increase your capacity or explore alternatives below."
            )
            suggested_actions = ["Explore Alternatives", "What should I do?"]
        else:
            surplus = analysis.cash_flow.remaining_goal_capacity
            reply += f"You have an unallocated surplus capacity of ₹{surplus:,.0f}/month!"
            suggested_actions = ["What are my goals?", "What if I save ₹5,000 more?"]

    # ─────────────────────────────────────────────────────────────────────────────
    # 3. EXPENSES
    # ─────────────────────────────────────────────────────────────────────────────
    elif intent == "EXPENSE_QUERY":
        expenses = db.query(Expense).filter(Expense.user_id == current_user.id).all()
        total_exp = sum((e.amount for e in expenses), Decimal("0.00"))
        cat_map: Dict[str, Decimal] = {}
        for e in expenses:
            cat_map[e.category] = cat_map.get(e.category, Decimal("0.00")) + e.amount

        top_cats = sorted(cat_map.items(), key=lambda x: x[1], reverse=True)[:3]
        top_str = "\n".join([f"• {cat}: ₹{amt:,.0f}" for cat, amt in top_cats]) if top_cats else "• No categorized expenses."

        reply = (
            f"Here is your current expense summary:\n\n"
            f"• Total Logged Expenses: ₹{total_exp:,.0f}\n\n"
            f"Top Spending Categories:\n{top_str}\n\n"
            f"Controlling flexible expenses can help free up monthly capacity for your goals."
        )
        suggested_actions = ["How to resolve conflict?", "Explore Alternatives"]

    # ─────────────────────────────────────────────────────────────────────────────
    # 4. INVESTMENTS
    # ─────────────────────────────────────────────────────────────────────────────
    elif intent == "INVESTMENT_QUERY":
        invs = db.query(Investment).filter(Investment.user_id == current_user.id).all()
        total_monthly_inv = sum((i.monthly_contribution for i in invs), Decimal("0.00"))
        total_paid = sum((i.total_paid for i in invs), Decimal("0.00"))

        inv_names = [f"• {i.name} ({i.type}): ₹{i.monthly_contribution:,.0f}/month" for i in invs]
        inv_str = "\n".join(inv_names) if inv_names else "• No active investments logged."

        reply = (
            f"Here is your investment portfolio status:\n\n"
            f"• Active Investments: {len(invs)}\n"
            f"• Total Portfolio Value Paid: ₹{total_paid:,.0f}\n"
            f"• Monthly Investment Commitment: ₹{total_monthly_inv:,.0f}/month\n\n"
            f"{inv_str}"
        )
        suggested_actions = ["Can I afford all my goals?", "Explore Alternatives"]

    # ─────────────────────────────────────────────────────────────────────────────
    # 5. GOALS QUERY
    # ─────────────────────────────────────────────────────────────────────────────
    elif intent == "GOALS_QUERY":
        if not analysis.goals:
            reply = "You do not have any active financial goals yet. Add goals using the '+' button on the Goals screen."
            suggested_actions = ["Can I afford all my goals?"]
        else:
            lines = []
            for g in analysis.goals:
                status = "Feasible" if g.is_feasible else "Infeasible"
                lines.append(
                    f"• {g.name} [{status}]: Target ₹{g.target_amount:,.0f} by {g.deadline}. "
                    f"Required: ₹{g.required_monthly_contribution:,.0f}/month."
                )
            reply = (
                f"You have {len(analysis.goals)} active financial goal(s):\n\n"
                f"{chr(10).join(lines)}\n\n"
                f"Total Monthly Savings Required: ₹{analysis.conflict.total_required_contribution:,.0f}/month "
                f"(Available Capacity: ₹{analysis.cash_flow.available_capacity:,.0f}/month)."
            )
            suggested_actions = ["Why are my goals conflicting?", "Explore Alternatives"] if analysis.conflict.has_conflict else ["What if I save ₹5,000 more?"]

    # ─────────────────────────────────────────────────────────────────────────────
    # 6. ACTIONABLE CONFLICT ADVICE ("What should I do?")
    # ─────────────────────────────────────────────────────────────────────────────
    elif intent == "ACTIONABLE_ADVICE":
        if not analysis.conflict.has_conflict:
            reply = "All your goals are currently in balance! You do not need to take corrective action right now."
            suggested_actions = ["What are my goals?", "What if I save ₹5,000 more?"]
        else:
            shortfall = analysis.conflict.monthly_shortfall
            needed_cap = analysis.conflict.total_required_contribution
            sc_count = len(analysis.scenarios)
            reply = (
                f"You currently have a shortfall of ₹{shortfall:,.0f}/month. Here are the 3 recommended ways to resolve it:\n\n"
                f"1. **Increase Monthly Capacity**: Tap 'Edit' on the capacity card and adjust from ₹{analysis.cash_flow.available_capacity:,.0f} "
                f"to ₹{needed_cap:,.0f}/month.\n"
                f"2. **Apply a Trade-off Scenario**: Choose from {sc_count} mathematically generated plans that automatically adjust timelines or targets.\n"
                f"3. **Extend Individual Deadlines**: Edit your goals to give yourself more months to save."
            )
            suggested_actions = ["Explore Alternatives", "Apply Option 1", "Why are they conflicting?"]

    # ─────────────────────────────────────────────────────────────────────────────
    # 7. CONFLICT ANALYSIS
    # ─────────────────────────────────────────────────────────────────────────────
    elif intent == "ANALYZE_CONFLICT":
        if not analysis.conflict.has_conflict:
            reply = "Great news! Your active goals are completely in harmony and fit comfortably within your monthly capacity."
            suggested_actions = ["What are my goals?", "What if I save ₹5,000 more?"]
        else:
            affected_str = ", ".join(analysis.conflict.affected_goal_names)
            reply = (
                f"Your goals are conflicting because the total required monthly savings of "
                f"₹{analysis.conflict.total_required_contribution:,.0f}/month exceeds your monthly capacity of "
                f"₹{analysis.cash_flow.available_capacity:,.0f}/month by ₹{analysis.conflict.monthly_shortfall:,.0f}/month.\n\n"
                f"• Competing Goals: {affected_str}\n"
                f"• Root Cause: Multiple goals have overlapping deadlines requiring aggressive simultaneous contributions.\n\n"
                f"I have generated {len(analysis.scenarios)} feasible alternative scenarios to balance your budget."
            )
            suggested_actions = ["Explore Alternatives", "What should I do?"]

    # ─────────────────────────────────────────────────────────────────────────────
    # 8. GENERATE / EXPLAIN SCENARIOS
    # ─────────────────────────────────────────────────────────────────────────────
    elif intent == "GENERATE_SCENARIOS":
        sc_count = len(analysis.scenarios)
        if sc_count == 0:
            reply = "No trade-off scenarios are currently needed because your goals are feasible or no goals exist."
        else:
            reply = f"I calculated {sc_count} feasible alternative plans for you:\n\n"
            for idx, sc in enumerate(analysis.scenarios, 1):
                reply += f"• **Option {idx}: {sc.name}**\n  {sc.description}\n\n"
            reply += "You can apply any option directly by tapping below or saying 'Apply Option 1'."
            suggested_actions = [f"Apply Option {i}" for i in range(1, min(4, sc_count + 1))]

    # ─────────────────────────────────────────────────────────────────────────────
    # 9. APPLY SCENARIO (Direct or Confirmation)
    # ─────────────────────────────────────────────────────────────────────────────
    elif intent == "APPLY_SCENARIO":
        msg = request.message.lower()
        target_idx = 0
        match = re.search(r"option\s*(\d+)", msg)
        if match:
            target_idx = max(0, int(match.group(1)) - 1)

        if analysis.scenarios and target_idx < len(analysis.scenarios):
            target_sc = analysis.scenarios[target_idx]
            # Execute application directly
            success = apply_scenario(db, current_user, target_sc.id)
            if success:
                db.commit()
                # Re-calculate fresh analysis
                fresh_analysis = get_full_financial_analysis(db, current_user, today=today)
                new_shortfall = fresh_analysis.conflict.monthly_shortfall
                has_conf = fresh_analysis.conflict.has_conflict

                if not has_conf:
                    reply = (
                        f"🎉 **Successfully applied '{target_sc.name}'!**\n\n"
                        f"Your goals have been updated. All goals are now 100% mathematically feasible within your "
                        f"monthly capacity of ₹{fresh_analysis.cash_flow.available_capacity:,.0f}!"
                    )
                    suggested_actions = ["What are my goals?", "Can I afford all my goals?"]
                else:
                    reply = (
                        f"✅ **Applied '{target_sc.name}'!**\n\n"
                        f"Your required contributions have been reduced to ₹{fresh_analysis.conflict.total_required_contribution:,.0f}/month. "
                        f"Remaining shortfall is now down to ₹{new_shortfall:,.0f}/month."
                    )
                    suggested_actions = ["What should I do?", "Explore Alternatives"]
                analysis = fresh_analysis
            else:
                reply = f"Could not apply '{target_sc.name}'. Please try selecting it from the Alternatives screen."
                suggested_actions = ["Explore Alternatives"]
        else:
            reply = "No matching scenario was found to apply. Please choose from the available options."
            suggested_actions = ["Explore Alternatives"]

    # ─────────────────────────────────────────────────────────────────────────────
    # 10. FINANCIAL IMPACT (What-If)
    # ─────────────────────────────────────────────────────────────────────────────
    elif intent == "ASK_FINANCIAL_IMPACT":
        amount_match = re.search(r"(?:₹|\b)(\d[\d,]*)\b", request.message)
        added_amount = Decimal(amount_match.group(1).replace(",", "")) if amount_match else Decimal("5000.00")

        new_cap = analysis.cash_flow.available_capacity + added_amount
        new_shortfall = max(Decimal("0.00"), analysis.conflict.total_required_contribution - new_cap)

        if new_shortfall == Decimal("0.00"):
            reply = (
                f"If you increase your monthly savings by ₹{added_amount:,.0f}, your monthly capacity becomes "
                f"₹{new_cap:,.0f}/month.\n\n"
                f"🎉 **This completely resolves your conflict!** All your active goals become fully feasible."
            )
            suggested_actions = ["What are my goals?", "Explore Alternatives"]
        else:
            reply = (
                f"If you increase your monthly savings by ₹{added_amount:,.0f}, your capacity increases to "
                f"₹{new_cap:,.0f}/month.\n\n"
                f"Your monthly shortfall decreases from ₹{analysis.conflict.monthly_shortfall:,.0f} "
                f"to ₹{new_shortfall:,.0f}/month."
            )
            suggested_actions = ["What should I do?", "Explore Alternatives"]

    # ─────────────────────────────────────────────────────────────────────────────
    # 11. GENERAL ANALYSIS FALLBACK
    # ─────────────────────────────────────────────────────────────────────────────
    else:
        if not analysis.goals:
            reply = "You haven't set any financial goals yet. Create goals on the Goals screen to analyze your financial health."
            suggested_actions = ["Add a Financial Goal"]
        elif not analysis.conflict.has_conflict:
            reply = (
                f"Yes! Based on your current income and expenses, your available monthly capacity is "
                f"₹{analysis.cash_flow.available_capacity:,.0f}/month. All your active goals require "
                f"₹{analysis.conflict.total_required_contribution:,.0f}/month, which is fully feasible with a surplus of "
                f"₹{analysis.cash_flow.remaining_goal_capacity:,.0f}/month."
            )
            suggested_actions = ["What are my goals?", "What if I save ₹5,000 more?"]
        else:
            reply = (
                f"Currently, your financial plan has an active funding shortfall. Your available monthly capacity is "
                f"₹{analysis.cash_flow.available_capacity:,.0f}/month, while your active goals require "
                f"₹{analysis.conflict.total_required_contribution:,.0f}/month. This creates a "
                f"₹{analysis.conflict.monthly_shortfall:,.0f}/month shortfall.\n\n"
                f"{analysis.conflict.conflict_reason}"
            )
            suggested_actions = ["What should I do?", "Explore Alternatives", "Why are they conflicting?"]

    return AIChatResponse(
        reply=reply,
        intent=intent,
        analysis=analysis,
        scenarios=analysis.scenarios,
        suggested_actions=suggested_actions,
        requires_confirmation=requires_confirmation,
        pending_scenario_id=pending_scenario_id,
    )
