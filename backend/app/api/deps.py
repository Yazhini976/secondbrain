

import os
import uuid
from typing import Generator
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.security import verify_id_token
from app.models.user import User
from app.services.user_service import get_or_create_user

from app.core.config import settings

# HTTP Bearer Token Security Scheme
auth_scheme = HTTPBearer(auto_error=False)


def _resolve_dev_token(token: str) -> dict | None:
    """
    If development mode is active and not in unit testing mode, resolve test/dev tokens without Firebase.
    Returns a dev payload dict, or None if not a dev token.
    In production (ENVIRONMENT == 'production' or DEV_MODE_ENABLED == False), dev tokens are strictly disabled.
    """
    if not settings.is_dev_mode:
        return None
    if settings.TESTING:
        # In unit tests, let security.verify_id_token handle test-token-* per test fixture
        return None
    # Accept: 'test-token-*' or 'dev-*' tokens for development
    if token.startswith("test-token-") or token.startswith("dev-"):
        uid = settings.DEV_USER_UID
        return {"uid": uid, "email": settings.DEV_USER_EMAIL, "name": "Dev User"}
    return None


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(auth_scheme),
    db: Session = Depends(get_db),
) -> User:
    """
    FastAPI dependency that extracts, verifies, and synchronizes the authenticated user.

    Flow:
    1. Reads Bearer token from 'Authorization: Bearer <ID_TOKEN>' header.
    2. In DEV_MODE: resolves dev/test tokens directly without Firebase.
    3. Otherwise: verifies token using Firebase Admin SDK via security module.
    4. Extracts verified Firebase UID (external_auth_id).
    5. Finds or creates corresponding PostgreSQL User record.
    6. Rejects inactive user accounts with 401.
    7. Returns authenticated User instance.

    Raises:
        HTTPException 401: If token is missing, invalid, expired, or user is inactive.
    """
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authorization token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials

    # ── Native Second Brain Auth Token ─────────────────────────────────────────
    if token.startswith("sb-auth-"):
        parts = token.split("-")
        if len(parts) >= 7:
            user_id_str = "-".join(parts[2:7])
            try:
                target_user_id = uuid.UUID(user_id_str)
                user = db.query(User).filter(User.id == target_user_id).first()
                if user:
                    if not user.is_active:
                        raise HTTPException(
                            status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="User account is inactive.",
                            headers={"WWW-Authenticate": "Bearer"},
                        )
                    return user
            except Exception:
                pass

    # ── Dev Mode Bypass ────────────────────────────────────────────────────────
    dev_payload = _resolve_dev_token(token)
    if dev_payload is not None:
        payload = dev_payload
    else:
        # ── Firebase Verification ──────────────────────────────────────────────
        try:
            payload = verify_id_token(token)
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=str(exc),
                headers={"WWW-Authenticate": "Bearer"},
            )
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate authentication credentials.",
                headers={"WWW-Authenticate": "Bearer"},
            )

    external_auth_id = payload.get("uid") or payload.get("sub")
    if not external_auth_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload: missing external user identifier.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    email = payload.get("email")
    display_name = payload.get("name") or payload.get("display_name")

    # Look up or synchronize PostgreSQL user
    user = get_or_create_user(
        db,
        external_auth_id=external_auth_id,
        email=email,
        display_name=display_name,
    )

    # Check user account status
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account is inactive.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user
