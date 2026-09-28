import uuid
from datetime import date
from decimal import Decimal
from typing import List, Optional, Dict
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.expense import Expense
from app.schemas.expense import (
    ExpenseCreate,
    ExpenseUpdate,
    ExpenseMonthlySummary,
    ALLOWED_EXPENSE_CATEGORIES,
)


def create_expense(
    db: Session,
    current_user: User,
    expense_in: ExpenseCreate,
) -> Expense:
    """
    Creates a new expense strictly scoped to the authenticated current_user.
    Never trusts client-supplied user_id.
    """
    expense = Expense(
        user_id=current_user.id,
        merchant=expense_in.merchant.strip(),
        amount=expense_in.amount,
        category=expense_in.category,
        transaction_date=expense_in.transaction_date,
        notes=expense_in.notes.strip() if expense_in.notes else None,
    )
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense


def get_expense(
    db: Session,
    current_user: User,
    expense_id: uuid.UUID,
) -> Optional[Expense]:
    """
    Retrieves an expense by ID ONLY if it belongs to the authenticated current_user.
    Prevents horizontal privilege escalation.
    """
    stmt = select(Expense).where(
        Expense.id == expense_id,
        Expense.user_id == current_user.id,
    )
    return db.scalars(stmt).first()


def list_expenses(
    db: Session,
    current_user: User,
    year: Optional[int] = None,
    month: Optional[int] = None,
    category: Optional[str] = None,
    page: int = 1,
    page_size: int = 100,
) -> List[Expense]:
    """
    Lists expenses belonging to current_user with optional month and category filters.
    Ordered by transaction_date DESC, created_at DESC.
    """
    stmt = select(Expense).where(Expense.user_id == current_user.id)

    # Date / Month Filtering
    if year is not None and month is not None:
        if not (1 <= month <= 12):
            raise ValueError("Month must be between 1 and 12.")
        start_date = date(year, month, 1)
        next_month = 1 if month == 12 else month + 1
        next_year = year + 1 if month == 12 else year
        end_date = date(next_year, next_month, 1)
        stmt = stmt.where(
            Expense.transaction_date >= start_date,
            Expense.transaction_date < end_date,
        )

    # Category Filtering
    if category:
        if category not in ALLOWED_EXPENSE_CATEGORIES:
            raise ValueError(
                f"Invalid expense category '{category}'. Allowed categories: {', '.join(sorted(ALLOWED_EXPENSE_CATEGORIES))}"
            )
        stmt = stmt.where(Expense.category == category)

    # Sorting
    stmt = stmt.order_by(Expense.transaction_date.desc(), Expense.created_at.desc())

    # Pagination
    safe_page = max(1, page)
    safe_page_size = min(max(1, page_size), 100)
    stmt = stmt.offset((safe_page - 1) * safe_page_size).limit(safe_page_size)

    return list(db.scalars(stmt).all())


def update_expense(
    db: Session,
    current_user: User,
    expense_id: uuid.UUID,
    expense_in: ExpenseUpdate,
) -> Optional[Expense]:
    """
    Updates an expense belonging to current_user.
    Returns None if the expense does not exist or belongs to another user.
    """
    expense = get_expense(db, current_user, expense_id)
    if not expense:
        return None

    if expense_in.merchant is not None:
        expense.merchant = expense_in.merchant.strip()
    if expense_in.amount is not None:
        expense.amount = expense_in.amount
    if expense_in.category is not None:
        expense.category = expense_in.category
    if expense_in.transaction_date is not None:
        expense.transaction_date = expense_in.transaction_date
    if expense_in.notes is not None:
        expense.notes = expense_in.notes.strip() if expense_in.notes else None

    db.commit()
    db.refresh(expense)
    return expense


def delete_expense(
    db: Session,
    current_user: User,
    expense_id: uuid.UUID,
) -> bool:
    """
    Deletes an expense belonging to current_user.
    Returns True if deleted, False if not found or unauthorized.
    """
    expense = get_expense(db, current_user, expense_id)
    if not expense:
        return False

    db.delete(expense)
    db.commit()
    return True


def get_monthly_summary(
    db: Session,
    current_user: User,
    year: int,
    month: int,
) -> ExpenseMonthlySummary:
    """
    Calculates monthly total and category breakdowns for current_user using PostgreSQL aggregation.
    """
    if not (1 <= month <= 12):
        raise ValueError("Month must be between 1 and 12.")

    start_date = date(year, month, 1)
    next_month = 1 if month == 12 else month + 1
    next_year = year + 1 if month == 12 else year
    end_date = date(next_year, next_month, 1)

    # 1. Total amount query
    total_stmt = select(
        func.coalesce(func.sum(Expense.amount), Decimal("0.00"))
    ).where(
        Expense.user_id == current_user.id,
        Expense.transaction_date >= start_date,
        Expense.transaction_date < end_date,
    )
    overall_total = db.scalar(total_stmt) or Decimal("0.00")

    # 2. Category breakdown query
    cat_stmt = select(
        Expense.category,
        func.coalesce(func.sum(Expense.amount), Decimal("0.00"))
    ).where(
        Expense.user_id == current_user.id,
        Expense.transaction_date >= start_date,
        Expense.transaction_date < end_date,
    ).group_by(Expense.category)

    cat_results = db.execute(cat_stmt).all()

    # Pre-populate all allowed categories with Decimal("0.00")
    category_totals: Dict[str, Decimal] = {cat: Decimal("0.00") for cat in sorted(ALLOWED_EXPENSE_CATEGORIES)}
    for cat_name, cat_total in cat_results:
        if cat_name in category_totals:
            category_totals[cat_name] = cat_total

    return ExpenseMonthlySummary(
        year=year,
        month=month,
        total=overall_total,
        category_totals=category_totals,
    )
