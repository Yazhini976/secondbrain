import logging
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.api.routes import health, auth, expenses, investments, documents, reminders, financial

logger = logging.getLogger("second_brain")

docs_enabled = (
    settings.ENABLE_DOCS
    if settings.ENABLE_DOCS is not None
    else (settings.ENVIRONMENT != "production")
)

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_PREFIX}/openapi.json" if docs_enabled else None,
    docs_url=f"{settings.API_PREFIX}/docs" if docs_enabled else None,
    redoc_url=f"{settings.API_PREFIX}/redoc" if docs_enabled else None,
)

# Configure CORS for Flutter mobile and Web deployments
if settings.CORS_ORIGINS:
    allow_wildcard = "*" in settings.CORS_ORIGINS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=not allow_wildcard,
        allow_methods=["*"],
        allow_headers=["*"],
    )


# Root endpoints
@app.get("/", status_code=status.HTTP_200_OK)
def root():
    """Root endpoint for basic backend validation."""
    return {"message": "Second Brain API"}


@app.get("/health", status_code=status.HTTP_200_OK)
def root_health():
    """Root health endpoint."""
    return {"status": "ok"}


if docs_enabled:
    from fastapi.responses import RedirectResponse

    @app.get("/docs", include_in_schema=False)
    def docs_redirect():
        """Convenience redirect from root /docs to /api/v1/docs."""
        return RedirectResponse(url=f"{settings.API_PREFIX}/docs")


# Centralized API Router Registration under /api/v1
app.include_router(health.router, prefix=settings.API_PREFIX, tags=["Health"])
app.include_router(auth.router, prefix=f"{settings.API_PREFIX}/auth", tags=["Auth"])
app.include_router(expenses.router, prefix=f"{settings.API_PREFIX}/expenses", tags=["Expenses"])
app.include_router(investments.router, prefix=f"{settings.API_PREFIX}/investments", tags=["Investments"])
app.include_router(documents.router, prefix=f"{settings.API_PREFIX}/documents", tags=["Documents"])
app.include_router(reminders.router, prefix=f"{settings.API_PREFIX}/reminders", tags=["Reminders"])
app.include_router(financial.router, prefix=f"{settings.API_PREFIX}/financial", tags=["Financial Intelligence"])


# Global exception handler - prevents leaking internal diagnostics in production
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    if settings.ENVIRONMENT == "production":
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"detail": "An internal server error occurred."},
        )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": str(exc)},
    )
