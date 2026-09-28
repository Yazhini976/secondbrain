from typing import Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.config import settings
from app.db.session import get_db
from app.models.user import User
from app.schemas.user import UserResponse
from app.schemas.auth import SignUpRequest, LoginRequest, AuthResponse, FinancialProfileUpdate
from app.services.seed_service import seed_user_dummy_data
from app.services import auth_service

router = APIRouter()


@router.post("/signup", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def signup_endpoint(
    signup_in: SignUpRequest,
    db: Session = Depends(get_db),
):
    """
    Registers a new user account with Name, Email, Phone, Password, and Monthly Income.
    Stores hashed credentials securely in PostgreSQL database.
    """
    try:
        user, token = auth_service.signup_user(db, signup_in)
        return AuthResponse(access_token=token, user=user)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))


@router.post("/login", response_model=AuthResponse, status_code=status.HTTP_200_OK)
def login_endpoint(
    login_in: LoginRequest,
    db: Session = Depends(get_db),
):
    """
    Authenticates an existing user via Email or Phone and Password.
    Returns access token and authenticated user profile.
    """
    try:
        user, token = auth_service.authenticate_user(db, login_in)
        return AuthResponse(access_token=token, user=user)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc))


@router.get("/me", response_model=UserResponse, status_code=status.HTTP_200_OK)
def get_current_user_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Protected Endpoint: Returns profile details of the currently authenticated PostgreSQL user.
    Includes display_name, email, phone, monthly_income, and monthly_capacity.
    """
    if not settings.TESTING:
        seed_user_dummy_data(db, current_user.id, force=False)
    return current_user


@router.patch("/financial-profile", response_model=UserResponse, status_code=status.HTTP_200_OK)
def update_financial_profile_endpoint(
    update_in: FinancialProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Protected Endpoint: Updates user's monthly income and/or financial capacity directly in PostgreSQL.
    """
    updated_user = auth_service.update_user_financial_profile(
        db,
        current_user,
        monthly_income=update_in.monthly_income,
        monthly_capacity=update_in.monthly_capacity,
    )
    return updated_user


@router.post("/seed-dummy-data", status_code=status.HTTP_200_OK)
def seed_dummy_data_endpoint(
    force: bool = Query(True, description="Whether to overwrite existing user data"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    """
    Protected Endpoint: Explicitly seeds dummy data (expenses, investments, documents,
    reminders, goals, scenarios) into the PostgreSQL database for the authenticated user.
    """
    result = seed_user_dummy_data(db, current_user.id, force=force)
    return {
        "message": "Dummy data seeded successfully into PostgreSQL database",
        "user_id": str(current_user.id),
        "details": result,
    }
