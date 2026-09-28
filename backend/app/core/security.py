"""
Security Module for Second Brain API.

Handles token verification using Firebase Admin SDK and security helper utilities.
"""

from typing import Dict, Any
from app.core.config import settings
from app.core.firebase import verify_firebase_token


def verify_id_token(token: str) -> Dict[str, Any]:
    """
    Verifies an incoming Bearer token.
    Delegates token verification to Firebase Admin SDK.
    In testing environment (TESTING=True), allows verifying mock test tokens.
    """
    if settings.TESTING and token.startswith("test-token-"):
        uid = token.replace("test-token-", "")
        return {
            "uid": uid,
            "sub": uid,
            "email": f"{uid}@example.com",
            "name": f"Test User {uid}",
        }
    
    return verify_firebase_token(token)
