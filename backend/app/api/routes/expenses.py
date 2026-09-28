import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.expense import (
    ExpenseCreate,
    ExpenseUpdate,
    ExpenseResponse,
    ExpenseMonthlySummary,
)
from app.services import expense_service

router = APIRouter()


@router.post("", response_model=ExpenseResponse, status_code=status.HTTP_201_CREATED)
def create_expense_endpoint(
    expense_in: ExpenseCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Creates a new expense transaction for the authenticated user.
    """
    return expense_service.create_expense(db, current_user, expense_in)


@router.get("", response_model=List[ExpenseResponse], status_code=status.HTTP_200_OK)
def list_expenses_endpoint(
    year: Optional[int] = Query(None, ge=2000, le=2100, description="Filter by transaction year"),
    month: Optional[int] = Query(None, ge=1, le=12, description="Filter by transaction month (1..12)"),
    category: Optional[str] = Query(None, description="Filter by category"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(100, ge=1, le=100, description="Page size limit"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Lists expense transactions belonging to the authenticated user with optional month and category filters.
    """
    try:
        return expense_service.list_expenses(
            db,
            current_user,
            year=year,
            month=month,
            category=category,
            page=page,
            page_size=page_size,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))


@router.get("/summary", response_model=ExpenseMonthlySummary, status_code=status.HTTP_200_OK)
def get_monthly_summary_endpoint(
    year: int = Query(..., ge=2000, le=2100, description="Year for monthly summary"),
    month: int = Query(..., ge=1, le=12, description="Month (1..12) for monthly summary"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Calculates monthly total spending and category breakdown for the authenticated user.
    """
    try:
        return expense_service.get_monthly_summary(db, current_user, year=year, month=month)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))


@router.get("/{expense_id}", response_model=ExpenseResponse, status_code=status.HTTP_200_OK)
def get_expense_endpoint(
    expense_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Retrieves a single expense transaction by ID.
    Returns 404 if the expense does not exist or belongs to another user.
    """
    expense = expense_service.get_expense(db, current_user, expense_id)
    if not expense:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found")
    return expense


@router.patch("/{expense_id}", response_model=ExpenseResponse, status_code=status.HTTP_200_OK)
def update_expense_endpoint(
    expense_id: uuid.UUID,
    expense_in: ExpenseUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Updates an existing expense transaction belonging to the authenticated user.
    """
    expense = expense_service.update_expense(db, current_user, expense_id, expense_in)
    if not expense:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found")
    return expense


@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_expense_endpoint(
    expense_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Deletes an existing expense transaction belonging to the authenticated user.
    """
    deleted = expense_service.delete_expense(db, current_user, expense_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found")
    return None
