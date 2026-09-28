from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.db.session import get_db

router = APIRouter()


@router.get("/health", status_code=status.HTTP_200_OK)
def get_health():
    """
    API Health Endpoint.
    Returns 200 OK to confirm the FastAPI backend service is running.
    """
    return {"status": "ok"}


@router.get("/health/db", status_code=status.HTTP_200_OK)
def get_db_health(db: Session = Depends(get_db)):
    """
    Database Health Check Endpoint.
    Executes a lightweight PostgreSQL query ('SELECT 1') to verify database connectivity.
    Does NOT fake a successful response if PostgreSQL is unreachable.
    """
    try:
        result = db.execute(text("SELECT 1")).scalar()
        if result == 1:
            return {
                "status": "ok",
                "database": "postgresql",
                "connected": True,
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Database returned unexpected response during health check."
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"PostgreSQL connection health check failed: {str(e)}"
        )
