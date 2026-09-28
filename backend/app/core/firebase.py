
import os
import logging
from typing import Dict, Any, Optional
import firebase_admin
from firebase_admin import credentials, auth
from app.core.config import settings

logger = logging.getLogger("second_brain.firebase")

_firebase_initialized = False


def initialize_firebase() -> Optional[firebase_admin.App]:
    """
    Initializes Firebase Admin SDK lazily if not already initialized.
    Supports service account JSON file or default project ID configuration.
    """
    global _firebase_initialized
    if _firebase_initialized or len(firebase_admin._apps) > 0:
        _firebase_initialized = True
        return firebase_admin.get_app()

    try:
        cred = None
        if settings.FIREBASE_CREDENTIALS_PATH and os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        elif settings.FIREBASE_PRIVATE_KEY and settings.FIREBASE_CLIENT_EMAIL:
            # Handle escaped newlines in PEM format often provided in cloud environment variables
            private_key = settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n")
            cred = credentials.Certificate({
                "type": "service_account",
                "project_id": settings.FIREBASE_PROJECT_ID,
                "private_key": private_key,
                "client_email": settings.FIREBASE_CLIENT_EMAIL,
                "token_uri": "https://oauth2.googleapis.com/token",
            })
        
        options = {}
        if settings.FIREBASE_PROJECT_ID:
            options["projectId"] = settings.FIREBASE_PROJECT_ID

        if cred:
            app = firebase_admin.initialize_app(cred, options)
        else:
            app = firebase_admin.initialize_app(options=options if options else None)
        
        _firebase_initialized = True
        logger.info("Firebase Admin SDK initialized successfully.")
        return app
    except Exception as e:
        logger.warning(f"Firebase Admin SDK initialization deferred: {e}")
        return None


def verify_firebase_token(token: str) -> Dict[str, Any]:
    """
    Verifies a Firebase ID token using Firebase Admin SDK.
    Returns decoded token dictionary containing 'uid', 'email', 'name', etc.

    Raises:
        ValueError: If token verification fails or token is expired/revoked.
    """
    initialize_firebase()
    try:
        decoded_token = auth.verify_id_token(token, check_revoked=False)
        return decoded_token
    except auth.ExpiredIdTokenError as exc:
        raise ValueError("Authentication token has expired.") from exc
    except auth.RevokedIdTokenError as exc:
        raise ValueError("Authentication token has been revoked.") from exc
    except auth.InvalidIdTokenError as exc:
        raise ValueError("Invalid authentication token.") from exc
    except Exception as exc:
        raise ValueError(f"Failed to verify authentication token: {str(exc)}") from exc
