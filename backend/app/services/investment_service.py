import uuid
from datetime import date
from decimal import Decimal
from typing import List, Optional
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.investment import Investment
from app.schemas.investment import (
    InvestmentCreate,
    InvestmentUpdate,
    InvestmentResponse,
    InvestmentSummaryResponse,
    ALLOWED_INVESTMENT_TYPES,
)


def calculate_investment_progress(installments_paid: int, total_installments: int) -> float:
    """
    Calculates installment progress percentage deterministically.
    Returns value between 0.0 and 100.0.
    """
    if total_installments <= 0:
        return 0.0
    ratio = installments_paid / total_installments
    return round(min(ratio * 100.0, 100.0), 2)


def calculate_investment_status(
    installments_paid: int,
    total_installments: int,
    next_due: Optional[date],
    maturity_date: Optional[date] = None,
    today: Optional[date] = None,
) -> str:
    """
    Derives investment status deterministically in Python domain layer.
    
    Priority Order:
    1. Completed  — installments_paid >= total_installments (if total_installments > 0)
                    or maturity_date is in the past
    2. Overdue    — next_due is in the past (< today)
    3. Due Soon   — next_due is within next 5 days (0 <= (next_due - today).days <= 5)
    4. On Track   — otherwise
    """
    if today is None:
        today = date.today()

    if total_installments > 0 and installments_paid >= total_installments:
        return "Completed"

    if maturity_date is not None and maturity_date < today:
        if total_installments == 0 or installments_paid >= total_installments:
            return "Completed"

    if next_due is not None:
        if next_due < today:
            return "Overdue"
        days_diff = (next_due - today).days
        if 0 <= days_diff <= 5:
            return "Due Soon"

    return "On Track"


def build_investment_response(investment: Investment, today: Optional[date] = None) -> InvestmentResponse:
    """
    Constructs an InvestmentResponse schema from an Investment ORM object with derived status and progress.
    """
    next_due_val = investment.next_due
    status_str = calculate_investment_status(
        installments_paid=investment.installments_paid,
        total_installments=investment.total_installments,
        next_due=next_due_val,
        maturity_date=investment.maturity_date,
        today=today,
    )
    progress_val = calculate_investment_progress(
        installments_paid=investment.installments_paid,
        total_installments=investment.total_installments,
    )

    return InvestmentResponse(
        id=investment.id,
        name=investment.name,
        type=investment.type,
        monthly_contribution=investment.monthly_contribution,
        total_paid=investment.total_paid,
        total_installments=investment.total_installments,
        installments_paid=investment.installments_paid,
        start_date=investment.start_date,
        next_due=next_due_val,
        next_due_date=next_due_val,
        maturity_date=investment.maturity_date,
        notes=investment.notes,
        status=status_str,
        progress_percentage=progress_val,
        created_at=investment.created_at,
        updated_at=investment.updated_at,
    )


def create_investment(
    db: Session,
    current_user: User,
    investment_in: InvestmentCreate,
) -> InvestmentResponse:
    """
    Creates a new investment strictly scoped to current_user.
    Does not accept user_id, status, or progress from client.
    """
    due_date = investment_in.next_due or investment_in.next_due_date

    investment = Investment(
        user_id=current_user.id,
        name=investment_in.name.strip(),
        type=investment_in.type,
        monthly_contribution=investment_in.monthly_contribution,
        total_paid=investment_in.total_paid,
        total_installments=investment_in.total_installments,
        installments_paid=investment_in.installments_paid,
        start_date=investment_in.start_date,
        next_due=due_date,
        maturity_date=investment_in.maturity_date,
        notes=investment_in.notes.strip() if investment_in.notes else None,
    )
    db.add(investment)
    db.commit()
    db.refresh(investment)

    return build_investment_response(investment)


def get_investment(
    db: Session,
    current_user: User,
    investment_id: uuid.UUID,
) -> Optional[InvestmentResponse]:
    """
    Retrieves an investment by ID ONLY if it belongs to current_user.
    Returns None if not found or belongs to another user.
    """
    stmt = select(Investment).where(
        Investment.id == investment_id,
        Investment.user_id == current_user.id,
    )
    investment = db.scalars(stmt).first()
    if not investment:
        return None
    return build_investment_response(investment)


def get_investment_orm(
    db: Session,
    current_user: User,
    investment_id: uuid.UUID,
) -> Optional[Investment]:
    """Internal helper to retrieve raw ORM model scoped to current_user."""
    stmt = select(Investment).where(
        Investment.id == investment_id,
        Investment.user_id == current_user.id,
    )
    return db.scalars(stmt).first()


def list_investments(
    db: Session,
    current_user: User,
    type_filter: Optional[str] = None,
    page: int = 1,
    page_size: int = 100,
) -> List[InvestmentResponse]:
    """
    Lists investments belonging to current_user with optional type filter.
    Returns items ordered by status priority (Overdue -> Due Soon -> On Track -> Completed),
    then next_due ascending, then created_at descending.
    """
    stmt = select(Investment).where(Investment.user_id == current_user.id)

    if type_filter:
        if type_filter not in ALLOWED_INVESTMENT_TYPES:
            raise ValueError(
                f"Invalid investment type '{type_filter}'. Allowed types: {', '.join(sorted(ALLOWED_INVESTMENT_TYPES))}"
            )
        stmt = stmt.where(Investment.type == type_filter)

    orm_items = list(db.scalars(stmt).all())
    responses = [build_investment_response(item) for item in orm_items]

    # Deterministic sorting priority
    status_order = {
        "Overdue": 0,
        "Due Soon": 1,
        "On Track": 2,
        "Completed": 3,
    }

    def sort_key(resp: InvestmentResponse):
        due_key = resp.next_due or date.max
        return (
            status_order.get(resp.status, 4),
            due_key,
            resp.created_at,
        )

    responses.sort(key=sort_key)

    # Apply pagination
    safe_page = max(1, page)
    safe_page_size = min(max(1, page_size), 100)
    start_idx = (safe_page - 1) * safe_page_size
    end_idx = start_idx + safe_page_size

    return responses[start_idx:end_idx]


def update_investment(
    db: Session,
    current_user: User,
    investment_id: uuid.UUID,
    investment_in: InvestmentUpdate,
) -> Optional[InvestmentResponse]:
    """
    Updates an investment belonging to current_user.
    Recalculates status and progress_percentage dynamically.
    Returns None if not found or unauthorized.
    """
    investment = get_investment_orm(db, current_user, investment_id)
    if not investment:
        return None

    if investment_in.name is not None:
        investment.name = investment_in.name.strip()
    if investment_in.type is not None:
        investment.type = investment_in.type
    if investment_in.monthly_contribution is not None:
        investment.monthly_contribution = investment_in.monthly_contribution
    if investment_in.total_paid is not None:
        investment.total_paid = investment_in.total_paid
    if investment_in.total_installments is not None:
        investment.total_installments = investment_in.total_installments
    if investment_in.installments_paid is not None:
        investment.installments_paid = investment_in.installments_paid
    if investment_in.start_date is not None:
        investment.start_date = investment_in.start_date
    if investment_in.next_due is not None or investment_in.next_due_date is not None:
        investment.next_due = investment_in.next_due or investment_in.next_due_date
    if investment_in.maturity_date is not None:
        investment.maturity_date = investment_in.maturity_date
    if investment_in.notes is not None:
        investment.notes = investment_in.notes.strip() if investment_in.notes else None

    # Validate model constraints after applying update
    if (
        investment.total_installments > 0
        and investment.installments_paid > investment.total_installments
    ):
        raise ValueError(
            f"installments_paid ({investment.installments_paid}) cannot exceed total_installments ({investment.total_installments})."
        )

    if (
        investment.start_date
        and investment.maturity_date
        and investment.maturity_date < investment.start_date
    ):
        raise ValueError(
            f"maturity_date ({investment.maturity_date}) cannot be earlier than start_date ({investment.start_date})."
        )

    db.commit()
    db.refresh(investment)

    return build_investment_response(investment)


def delete_investment(
    db: Session,
    current_user: User,
    investment_id: uuid.UUID,
) -> bool:
    """
    Deletes an investment belonging to current_user.
    Returns True if deleted, False if not found or unauthorized.
    """
    investment = get_investment_orm(db, current_user, investment_id)
    if not investment:
        return False

    db.delete(investment)
    db.commit()
    return True


def get_investment_summary(
    db: Session,
    current_user: User,
) -> InvestmentSummaryResponse:
    """
    Calculates portfolio summary statistics for current_user.
    Financial calculations preserve Decimal precision.
    """
    stmt = select(Investment).where(Investment.user_id == current_user.id)
    investments = list(db.scalars(stmt).all())

    total_invested = Decimal("0.00")
    total_monthly_contribution = Decimal("0.00")
    active_count = 0
    completed_count = 0
    overdue_count = 0
    due_soon_count = 0

    today = date.today()

    for inv in investments:
        total_invested += inv.total_paid
        total_monthly_contribution += inv.monthly_contribution

        st = calculate_investment_status(
            installments_paid=inv.installments_paid,
            total_installments=inv.total_installments,
            next_due=inv.next_due,
            maturity_date=inv.maturity_date,
            today=today,
        )

        if st == "Completed":
            completed_count += 1
        else:
            active_count += 1
            if st == "Overdue":
                overdue_count += 1
            elif st == "Due Soon":
                due_soon_count += 1

    return InvestmentSummaryResponse(
        total_invested=total_invested,
        total_monthly_contribution=total_monthly_contribution,
        active_count=active_count,
        completed_count=completed_count,
        overdue_count=overdue_count,
        due_soon_count=due_soon_count,
    )
