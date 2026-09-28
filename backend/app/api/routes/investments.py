import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.investment import (
    InvestmentCreate,
    InvestmentUpdate,
    InvestmentResponse,
    InvestmentSummaryResponse,
)
from app.services import investment_service

router = APIRouter()


@router.post(
    "",
    response_model=InvestmentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new investment record",
    description="Creates an investment record scoped to the authenticated user. Status and progress are derived server-side.",
)
def create_investment(
    investment_in: InvestmentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    try:
        return investment_service.create_investment(db, current_user, investment_in)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )


@router.get(
    "",
    response_model=List[InvestmentResponse],
    status_code=status.HTTP_200_OK,
    summary="List all investments for current user",
    description="Returns user's investments with optional category type filtering. Items ordered by status priority and due dates.",
)
def list_investments(
    type: Optional[str] = Query(None, description="Optional investment type filter (e.g., FD, RD, Insurance)"),
    page: int = Query(1, ge=1),
    page_size: int = Query(100, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    try:
        return investment_service.list_investments(
            db,
            current_user,
            type_filter=type,
            page=page,
            page_size=page_size,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )


@router.get(
    "/summary",
    response_model=InvestmentSummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Get investment portfolio summary",
    description="Calculates total invested amount, monthly contributions, and count breakdowns by derived status.",
)
def get_investment_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return investment_service.get_investment_summary(db, current_user)


@router.get(
    "/{investment_id}",
    response_model=InvestmentResponse,
    status_code=status.HTTP_200_OK,
    summary="Get investment details by ID",
    description="Retrieves a specific investment by ID. Enforces strict user isolation.",
)
def get_investment(
    investment_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    investment = investment_service.get_investment(db, current_user, investment_id)
    if not investment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Investment not found.",
        )
    return investment


@router.patch(
    "/{investment_id}",
    response_model=InvestmentResponse,
    status_code=status.HTTP_200_OK,
    summary="Update an existing investment",
    description="Updates specified fields of an investment and recalculates status and progress.",
)
def update_investment(
    investment_id: uuid.UUID,
    investment_in: InvestmentUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    try:
        updated = investment_service.update_investment(
            db, current_user, investment_id, investment_in
        )
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Investment not found.",
            )
        return updated
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )


@router.delete(
    "/{investment_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete an investment",
    description="Deletes an investment record. Enforces user ownership.",
)
def delete_investment(
    investment_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    deleted = investment_service.delete_investment(db, current_user, investment_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Investment not found.",
        )
    return None
