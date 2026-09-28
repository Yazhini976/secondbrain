from decimal import Decimal
from typing import Optional
import logging
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from sqlalchemy import select

from app.models.user import User

logger = logging.getLogger("second_brain.user_service")


def get_user_by_external_id(db: Session, external_auth_id: str) -> Optional[User]:
    """
    Looks up a User by external_auth_id (e.g. Firebase UID).
    """
    stmt = select(User).where(User.external_auth_id == external_auth_id)
    return db.scalars(stmt).first()


def get_or_create_user(
    db: Session,
    external_auth_id: str,
    email: Optional[str] = None,
    display_name: Optional[str] = None,
) -> User:
    """
    Synchronizes authenticated identity with PostgreSQL.
    
    1. Looks up user by external_auth_id.
    2. Returns existing user if found.
    3. Creates a new User record if missing.
    4. Handles race conditions safely using database transactions & IntegrityError rollback.
    """
    user = get_user_by_external_id(db, external_auth_id)
    if user:
        # Update email/display_name if changed
        updated = False
        if email and user.email != email:
            user.email = email
            updated = True
        if display_name and user.display_name != display_name:
            user.display_name = display_name
            updated = True
        if getattr(user, "monthly_capacity", None) is None or user.monthly_capacity == Decimal("0.00"):
            user.monthly_capacity = Decimal("250000.00")
            updated = True
        if updated:
            db.commit()
            db.refresh(user)
        return user

    # Create new user record
    try:
        new_user = User(
            external_auth_id=external_auth_id,
            email=email,
            display_name=display_name,
            monthly_capacity=Decimal("250000.00"),
            is_active=True,
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        logger.info(f"Created new PostgreSQL user for external_auth_id='{external_auth_id}'")

        # Automatically seed dummy data for new user in database (except in testing mode)
        from app.core.config import settings
        if not settings.TESTING:
            try:
                from app.services.seed_service import seed_user_dummy_data
                seed_user_dummy_data(db, new_user.id)
            except Exception as seed_err:
                logger.warning(f"Could not seed dummy data for new user {new_user.id}: {seed_err}")

        return new_user
    except IntegrityError:
        # Concurrent request created user first; rollback and fetch created user
        db.rollback()
        user = get_user_by_external_id(db, external_auth_id)
        if user:
            return user
        raise RuntimeError("Failed to resolve user synchronization race condition.")
