#!/bin/sh
set -e

echo "[STARTUP] Applying database migrations via Alembic..."
alembic upgrade head

echo "[STARTUP] Starting FastAPI server on port ${PORT:-8000} with ${WEB_CONCURRENCY:-1} worker(s)..."
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}" --workers "${WEB_CONCURRENCY:-1}"
