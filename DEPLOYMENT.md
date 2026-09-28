# Second Brain - Production Deployment Guide

This guide provides end-to-end instructions for deploying both the **FastAPI Backend (with PostgreSQL)** and the **Flutter Mobile App**.

---

## Architecture Overview

```
                      +-----------------------------+
                      |   Flutter Mobile App        |
                      |   (Android / iOS)           |
                      +--------------+--------------+
                                     |
                                     | HTTPS / REST (API_URL)
                                     v
                      +-----------------------------+
                      |   FastAPI Backend (Python)  |
                      |   - Alembic Migrations      |
                      |   - Auth & Financial Engine |
                      |   - Health check: /health   |
                      +--------------+--------------+
                                     |
                                     | postgresql+psycopg://
                                     v
                      +-----------------------------+
                      |   PostgreSQL Database 16+   |
                      |   (Managed / Docker Volume) |
                      +-----------------------------+
```

---

## 1. Backend Deployment

### Option A: 1-Click Cloud Deployment on Render (Recommended)

Second Brain includes a native [render.yaml](file:///c:/Users/ASUS/OneDrive/Pictures/Desktop/SecondBrain/render.yaml) Blueprint that provisions both the **PostgreSQL database** and the **FastAPI web service** automatically.

1. Push your repository to GitHub or GitLab.
2. Go to [Render Dashboard](https://dashboard.render.com).
3. Click **New +** -> **Blueprint**.
4. Select your repository. Render will automatically parse [render.yaml](file:///c:/Users/ASUS/OneDrive/Pictures/Desktop/SecondBrain/render.yaml).
5. Click **Apply**.
   - Render creates a managed PostgreSQL database.
   - Render builds the backend, runs Alembic migrations (`alembic upgrade head`), and starts the service.
6. Your backend will be live at:
   `https://second-brain-api.onrender.com`

---

### Option B: VPS / Dedicated Server (Docker Compose)

Deploy to any Linux cloud server (DigitalOcean, AWS EC2, Hetzner, Linode, Ubuntu VPS):

1. **Clone the repo onto the server**:
   ```bash
   git clone <your-repo-url> /opt/secondbrain
   cd /opt/secondbrain
   ```

2. **Configure environment variables (optional)**:
   Create a `.env` in the root or pass environment variables:
   ```bash
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=supersecretsecurepassword
   POSTGRES_DB=second_brain
   BACKEND_PORT=8000
   ```

3. **Launch the stack with Docker Compose**:
   ```bash
   docker compose up -d --build
   ```

4. **Verify running containers & health status**:
   ```bash
   docker compose ps
   curl http://localhost:8000/health
   ```
   Both the PostgreSQL database and backend with automatic Alembic migrations will run with auto-restart (`restart: unless-stopped`).

---

### Option C: Railway / Supabase / Neon

1. **Database**: Create a PostgreSQL database on [Neon.tech](https://neon.tech) or [Supabase](https://supabase.com). Copy the connection URI.
2. **Web Service**: Deploy the `backend` folder to [Railway.app](https://railway.app):
   - Set Root Directory: `backend`
   - Set Environment Variables:
     - `ENVIRONMENT=production`
     - `DATABASE_URL=postgresql+psycopg://user:password@host:port/dbname`
     - `CORS_ORIGINS=["*"]`
     - `FIREBASE_DEV_MODE=true` (or `false` with service account)
   - Railway will detect the [Procfile](file:///c:/Users/ASUS/OneDrive/Pictures/Desktop/SecondBrain/backend/Procfile) and [Dockerfile](file:///c:/Users/ASUS/OneDrive/Pictures/Desktop/SecondBrain/backend/Dockerfile).

---

## 2. Environment Variables Reference

| Variable | Required | Default / Example | Purpose |
| :--- | :--- | :--- | :--- |
| `ENVIRONMENT` | Yes | `production` | Enables production mode and disables internal tracebacks. |
| `DATABASE_URL` | Yes | `postgresql+psycopg://...` | Connection string to PostgreSQL (SQLite is disallowed). |
| `CORS_ORIGINS` | No | `["*"]` | Allowed CORS origins (JSON array or comma-separated). |
| `FIREBASE_DEV_MODE` | No | `true` | Allows local/demo tokens without Firebase Admin credentials. |
| `FIREBASE_CREDENTIALS_PATH` | Prod | `/app/firebase-credentials.json` | Path to Firebase Admin service account key JSON file. |
| `PORT` | Auto | `8000` | Port assigned by hosting provider or Docker. |
| `WEB_CONCURRENCY` | No | `2` | Number of Uvicorn worker processes. |

---

## 3. Mobile App Deployment (Flutter)

The mobile client is configured with dynamic environment injection via `--dart-define=API_URL=...`.

### A. Build Release APK (Direct Install / Side-loading)

Replace `https://your-api.com/api/v1` with your deployed backend URL:

```bash
cd mobile
flutter build apk --release --dart-define=API_URL=https://your-api.com/api/v1
```

The compiled APK will be generated at:
`mobile/build/app/outputs/flutter-apk/app-release.apk`

---

### B. Build Google Play Store Bundle (.aab) with Keystore Signing

1. **Generate your upload keystore** (if you don't have one):
   ```bash
   keytool -genkey -v -keystore mobile/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Configure `mobile/android/key.properties`**:
   Copy [mobile/android/key.properties.example](file:///c:/Users/ASUS/OneDrive/Pictures/Desktop/SecondBrain/mobile/android/key.properties.example) to `mobile/android/key.properties`:
   ```properties
   keyAlias=upload
   keyPassword=your-key-password
   storeFile=../upload-keystore.jks
   storePassword=your-store-password
   ```
   *(Note: `key.properties` and `*.jks` are already git-ignored).*

3. **Build the production Android App Bundle**:
   ```bash
   cd mobile
   flutter build appbundle --release --dart-define=API_URL=https://your-api.com/api/v1
   ```

The signed bundle will be generated at:
`mobile/build/app/outputs/bundle/release/app-release.aab`
Upload this `.aab` file directly to the Google Play Console.

---

## 4. Verification & Health Monitoring

Once deployed:

1. **Backend Health Check**:
   ```bash
   curl -i https://<your-backend-host>/health
   # Expected response: HTTP 200 OK -> {"status":"ok"}
   ```

2. **Database Connectivity Health**:
   ```bash
   curl -i https://<your-backend-host>/api/v1/health
   # Expected response: HTTP 200 OK -> {"status":"healthy","database":"connected"}
   ```

3. **Mobile Connectivity**:
   - Open the release build on your Android device.
   - Sign up or log in. The app communicates directly with your deployed HTTPS backend endpoint.
