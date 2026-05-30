# Smart Campus Assistant: Deployment Readiness Plan

## Objective
Analyze the codebase and document all necessary modifications required before deploying the Smart Campus Assistant (FastAPI backend and Flutter frontend) to a production environment.

## Context
The system currently uses development configurations, local databases, and unencrypted traffic settings tailored for local emulators. Moving to production requires significant security, architectural, and configuration shifts.

## Implementation Steps

### 1. Backend Modifications (FastAPI)

*   **Database Architecture:**
    *   **Action:** Migrate from SQLite (`sqlite:///./campus.db`) to **PostgreSQL** or **MySQL**. Update `DATABASE_URL` in the production `.env`.
    *   **Reason:** SQLite locks on writes and will deadlock under concurrent load (e.g., live QR attendance).
*   **Security Credentials:**
    *   **Action:** Enforce `DEBUG=False` in production. Generate and strictly use environment variables for `SECRET_KEY` and `TOTP_ENCRYPTION_KEY`.
    *   **Reason:** Prevent fallback to hardcoded, insecure default keys.
*   **CORS (Cross-Origin Resource Sharing):**
    *   **Action:** Update `allow_origins=["*"]` in `app/main.py` to a strict list of allowed production domains.
    *   **Reason:** Prevent unauthorized websites from accessing the API.
*   **File Storage:**
    *   **Action:** Integrate AWS S3 or Google Cloud Storage for handling uploads (SSM certs, timetables).
    *   **Reason:** Local `uploads/` directories are ephemeral in containerized/cloud environments and will be lost on restart.
*   **Task Queue (Celery):**
    *   **Action:** Transition from the Windows-specific `-P solo` flag in `run_worker.py` to a standard process pool on Linux (e.g., `--concurrency=4`).
*   **Application Server:**
    *   **Action:** Serve the application using **Gunicorn** with Uvicorn workers instead of raw Uvicorn.

### 2. Frontend Modifications (Flutter)

*   **Network Security:**
    *   **Action:** Remove `android:usesCleartextTraffic="true"` from `AndroidManifest.xml`. Ensure all API connections use `HTTPS`/`WSS`.
    *   **Reason:** Required by app stores; prevents man-in-the-middle attacks.
*   **API Configuration:**
    *   **Action:** Update `lib/core/app_config.dart` to point to the production API domain instead of `10.0.2.2`. Use `--dart-define` for build-time configuration.
*   **App Security & Signing:**
    *   **Action:** Build with `--obfuscate` to protect API endpoints and logic. Configure release Keystores for production signing.

### 3. DevOps & Architecture

*   **Containerization:**
    *   **Action:** Create Dockerfiles and `docker-compose.yml` to orchestrate FastAPI, Celery, Redis, and PostgreSQL.
*   **Reverse Proxy & SSL:**
    *   **Action:** Deploy behind Nginx/Traefik and configure SSL via Let's Encrypt for secure `HTTPS` and `WSS` traffic.

## Verification
*   Confirm `.env` variables are strictly enforced.
*   Verify successful DB connection to Postgres/MySQL.
*   Ensure Flutter builds successfully with obfuscation and release signing.
*   Test end-to-end flow using the production HTTPS domain.
