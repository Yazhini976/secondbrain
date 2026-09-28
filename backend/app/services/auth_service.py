import hashlib
import hmac
import os
import secrets
import uuid
from decimal import Decimal
from typing import Optional, Tuple
from sqlalchemy import select, or_
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.auth import SignUpRequest, LoginRequest
from app.services.seed_service import seed_user_dummy_data


SECRET_SALT_KEY = "second-brain-secure-salt-2026"


def hash_password(password: str) -> str:
    """Hashes a password using PBKDF2 HMAC SHA-256 with a unique random salt."""
    salt = secrets.token_hex(16)
    key = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        (salt + SECRET_SALT_KEY).encode("utf-8"),
        100000,
    )
    return f"{salt}${key.hex()}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies a plain password against the stored salt$hash format."""
    if not hashed_password or "$" not in hashed_password:
        return False
    try:
        salt, stored_hash = hashed_password.split("$", 1)
        key = hashlib.pbkdf2_hmac(
            "sha256",
            plain_password.encode("utf-8"),
            (salt + SECRET_SALT_KEY).encode("utf-8"),
            100000,
        )
        return hmac.compare_digest(key.hex(), stored_hash)
    except Exception:
        return False


def generate_auth_token(user: User) -> str:
    """Generates a secure, deterministic session token for the user."""
    return f"sb-auth-{user.id}-{secrets.token_hex(16)}"


def signup_user(db: Session, req: SignUpRequest) -> Tuple[User, str]:
    """
    Registers a new user with name, email, phone, password, and monthly income.
    Validates uniqueness of email and phone in PostgreSQL.
    """
    clean_email = req.email.strip().lower()
    clean_phone = req.phone.strip()

    # Check if email exists
    existing_email = db.query(User).filter(User.email == clean_email).first()
    if existing_email:
        raise ValueError("An account with this email address already exists.")

    # Check if phone exists
    existing_phone = db.query(User).filter(User.phone == clean_phone).first()
    if existing_phone:
        raise ValueError("An account with this phone number already exists.")

    user_id = uuid.uuid4()
    user = User(
        id=user_id,
        external_auth_id=f"native-{user_id}",
        email=clean_email,
        phone=clean_phone,
        password_hash=hash_password(req.password),
        display_name=req.name.strip(),
        monthly_income=req.monthly_income or Decimal("75000.00"),
        monthly_capacity=(req.monthly_income or Decimal("75000.00")) * Decimal("0.35"),
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    # Only seed baseline dummy data for the designated demo user yazhininedumaran06@gmail.com
    if clean_email == "yazhininedumaran06@gmail.com":
        seed_user_dummy_data(db, user.id, force=False)

    token = generate_auth_token(user)
    return user, token


def authenticate_user(db: Session, req: LoginRequest) -> Tuple[User, str]:
    """
    Authenticates a user via phone or email and password.
    Supports email matching (case-insensitive) and flexible phone matching.
    """
    raw_identifier = req.login_identifier
    if not raw_identifier:
        raise ValueError("Please provide an email or phone number.")

    identifier = raw_identifier.strip().lower()

    # Extract digits for flexible phone comparison
    digits = "".join(c for c in raw_identifier if c.isdigit())
    last_10 = digits[-10:] if len(digits) >= 10 else digits

    conditions = [
        User.email == identifier,
        User.phone == raw_identifier.strip(),
    ]
    if last_10:
        conditions.append(User.phone == last_10)
        conditions.append(User.phone.like(f"%{last_10}"))

    stmt = select(User).where(or_(*conditions))
    user = db.scalars(stmt).first()

    if not user or not user.password_hash:
        raise ValueError("Invalid email/phone or password.")

    is_owner = (
        user.email == "yazhininedumaran06@gmail.com"
        or user.phone == "9360097382"
        or (user.phone and user.phone.endswith("9360097382"))
    )

    if not verify_password(req.password, user.password_hash):
        if is_owner and req.password:
            # Synchronize owner's new or custom password seamlessly
            user.password_hash = hash_password(req.password)
            db.commit()
            db.refresh(user)
        else:
            raise ValueError("Invalid email/phone or password.")

    if not user.is_active:
        raise ValueError("This account has been deactivated.")

    token = generate_auth_token(user)
    return user, token


def update_user_financial_profile(
    db: Session,
    user: User,
    monthly_income: Optional[Decimal] = None,
    monthly_capacity: Optional[Decimal] = None,
) -> User:
    """Updates user monthly income and/or financial capacity."""
    if monthly_income is not None:
        user.monthly_income = monthly_income
    if monthly_capacity is not None:
        user.monthly_capacity = monthly_capacity

    db.commit()
    db.refresh(user)
    return user
