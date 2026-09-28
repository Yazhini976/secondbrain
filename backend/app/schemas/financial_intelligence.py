import uuid
from datetime import date
from decimal import Decimal
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, ConfigDict, Field

from app.schemas.financial_goal import FinancialGoalResponse


class CashFlowSummary(BaseModel):
    monthly_income: Decimal = Field(..., description="Total monthly income")
    monthly_expenses: Decimal = Field(..., description="Essential monthly expenses")
    existing_commitments: Decimal = Field(..., description="Existing financial commitments (e.g., SIPs/investments)")
    available_capacity: Decimal = Field(..., description="Monthly capacity available for goals")
    total_goal_contributions: Decimal = Field(..., description="Sum of current goal contributions")
    remaining_goal_capacity: Decimal = Field(..., description="Available capacity minus total goal contributions")


class ConflictReport(BaseModel):
    has_conflict: bool = Field(..., description="True if conflict/shortfall detected")
    monthly_capacity: Decimal = Field(..., description="Available monthly capacity")
    total_required_contribution: Decimal = Field(..., description="Total required monthly contribution across goals")
    monthly_shortfall: Decimal = Field(..., description="Monthly shortfall / gap (Decimal)")
    affected_goal_ids: List[uuid.UUID] = Field(default_factory=list)
    affected_goal_names: List[str] = Field(default_factory=list)
    conflict_reason: str = Field(..., description="Deterministic human-readable explanation of conflict")


class GoalChangeDetail(BaseModel):
    goal_id: uuid.UUID
    goal_name: str
    action_type: str = Field(..., description="KEEP_TARGET, REDUCE_TARGET, EXTEND_DEADLINE, INCREASE_CONTRIBUTION, DECREASE_CONTRIBUTION, PAUSE_CONTRIBUTION")
    original_target: Decimal
    new_target: Decimal
    original_deadline: date
    new_deadline: date
    original_contribution: Decimal
    new_contribution: Decimal


class FinancialScenario(BaseModel):
    id: str
    name: str
    description: str
    changes: List[GoalChangeDetail]
    is_feasible: bool
    monthly_requirement: Decimal
    monthly_capacity: Decimal
    monthly_surplus_or_gap: Decimal
    affected_goals: List[str]
    tradeoffs: List[str]


class FinancialAnalysisResponse(BaseModel):
    cash_flow: CashFlowSummary
    goals: List[FinancialGoalResponse]
    conflict: ConflictReport
    scenarios: List[FinancialScenario]
    overall_feasibility: bool


class AIChatRequest(BaseModel):
    message: str = Field(..., min_length=1, description="Natural language question from user")
    context_override: Optional[Dict[str, Any]] = None


class AIChatResponse(BaseModel):
    reply: str = Field(..., description="Natural language explanation of verified financial results")
    intent: str = Field(..., description="Extracted intent name")
    analysis: Optional[FinancialAnalysisResponse] = None
    scenarios: Optional[List[FinancialScenario]] = None
    suggested_actions: List[str] = Field(default_factory=list)
    requires_confirmation: bool = False
    pending_scenario_id: Optional[str] = None
