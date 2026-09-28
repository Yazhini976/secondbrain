import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.financial_goal import (
    FinancialGoalCreate,
    FinancialGoalUpdate,
    FinancialGoalResponse,
)
from app.schemas.financial_intelligence import (
    FinancialAnalysisResponse,
    ConflictReport,
    FinancialScenario,
    AIChatRequest,
    AIChatResponse,
)
from app.services import financial_service
from app.services.cash_flow_engine import calculate_user_cash_flow
from app.services.conflict_detection_engine import analyze_multi_goal_conflict
from app.services.scenario_engine import generate_financial_scenarios, apply_scenario
from app.services.ai_interaction_service import get_full_financial_analysis, process_ai_interaction

router = APIRouter()


@router.get("/goals", response_model=List[FinancialGoalResponse], status_code=status.HTTP_200_OK)
def list_financial_goals_endpoint(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lists financial goals belonging to the authenticated user."""
    return financial_service.list_financial_goals(db, current_user)


@router.post("/goals", response_model=FinancialGoalResponse, status_code=status.HTTP_201_CREATED)
def create_financial_goal_endpoint(
    goal_in: FinancialGoalCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Creates a new financial goal for the authenticated user."""
    try:
        return financial_service.create_financial_goal(db, current_user, goal_in)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))


@router.get("/goals/{goal_id}", response_model=FinancialGoalResponse, status_code=status.HTTP_200_OK)
def get_financial_goal_endpoint(
    goal_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieves a single financial goal by ID."""
    goal = financial_service.get_financial_goal(db, current_user, goal_id)
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Financial goal not found")
    return goal


@router.patch("/goals/{goal_id}", response_model=FinancialGoalResponse, status_code=status.HTTP_200_OK)
def update_financial_goal_endpoint(
    goal_id: uuid.UUID,
    goal_in: FinancialGoalUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Updates a financial goal belonging to the authenticated user."""
    try:
        goal = financial_service.update_financial_goal(db, current_user, goal_id, goal_in)
        if not goal:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Financial goal not found")
        return goal
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))


@router.delete("/goals/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_financial_goal_endpoint(
    goal_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Deletes a financial goal belonging to the authenticated user."""
    deleted = financial_service.delete_financial_goal(db, current_user, goal_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Financial goal not found")
    return None


@router.get("/analysis", response_model=FinancialAnalysisResponse, status_code=status.HTTP_200_OK)
def get_financial_analysis_endpoint(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Runs the deterministic Financial Intelligence Engine and returns full cash flow, conflict, and scenarios."""
    return get_full_financial_analysis(db, current_user)


@router.post("/conflicts/analyze", response_model=ConflictReport, status_code=status.HTTP_200_OK)
def analyze_conflicts_endpoint(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Analyzes multi-goal conflicts deterministically."""
    analysis = get_full_financial_analysis(db, current_user)
    return analysis.conflict


@router.post("/scenarios/generate", response_model=List[FinancialScenario], status_code=status.HTTP_200_OK)
def generate_scenarios_endpoint(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Generates and evaluates mathematically feasible trade-off scenarios."""
    analysis = get_full_financial_analysis(db, current_user)
    return analysis.scenarios


@router.post("/scenarios/{scenario_id}/apply", status_code=status.HTTP_200_OK)
def apply_scenario_endpoint(
    scenario_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Applies a chosen financial scenario to PostgreSQL financial goals upon explicit user action."""
    success = apply_scenario(db, current_user, scenario_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Scenario not found or could not be applied")
    return {"message": f"Successfully applied scenario '{scenario_id}'", "status": "ok"}


@router.post("/ai/chat", response_model=AIChatResponse, status_code=status.HTTP_200_OK)
def ai_chat_endpoint(
    request: AIChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """AI Interaction Layer endpoint for natural language financial questions."""
    return process_ai_interaction(db, current_user, request)
