# Smart Campus Assistant — Unified Academic Ecosystem

## 📌 Project Overview
The **Smart Campus Assistant** is a high-performance, multi-role digital ecosystem designed to automate and streamline college operations. It provides a unified platform for Students, Faculty, HODs, and the Principal to manage attendance, digital timetables, academic performance tracking (SSM), and campus-wide grievances.

---

## 🏗 System Architecture

### Backend: FastAPI (Python)
- **High Performance:** Asynchronous API endpoints for real-time responsiveness.
- **Database:** SQLite with SQLAlchemy ORM for efficient data management.
- **Security:** Role-Based Access Control (RBAC) with JWT tokens and centralized environment variable enforcement.
- **Task Management:** Native `BackgroundTasks` for automated session ending (no Redis/Celery required).

### Frontend: Flutter (Dart)
- **Cross-Platform:** High-quality Material 3 mobile experience.
- **Dynamic UI:** Role-specific dashboards with interactive components like QR scanners and real-time class countdowns.
- **Theming:** Full Light/Dark mode support.

---

## 🚀 Core Modules

### 1. Smart QR Attendance
- **Faculty:** Generates a session-specific QR code.
- **Student:** Scans via the mobile app to mark instant, verified attendance.
- **Automated:** Sessions automatically close after the period ends via background tasks.

### 2. Digital Timetable & Smart Reminders
- **Real-time Schedule:** Students see a live countdown to their next class.
- **Faculty Editor:** Simple vertical interface for managing daily schedules and publishing updates instantly.

### 3. SSM (Student Skill Management) - Activity Based
A modern performance evaluation system that tracks students across five key pillars:
- **Academic:** Internal/University GPA and attendance tracking.
- **Development:** NPTEL certifications, internships, and competition results.
- **Skill & Readiness:** Technical/soft skills and placement preparation.
- **Discipline:** Punctuality, dress code, and department contributions.
- **Leadership:** Event management and class/college roles.
- **Workflow:** Students submit activity proofs → Mentors (CC) review → System calculates star ratings.

### 4. Complaints & Helpdesk
- Transparent tracking of student grievances with escalation logic to HODs and the Principal.

---

## 👥 User Roles
- **Student:** Marks attendance, tracks SSM activities, views timetables, and lodges complaints.
- **Faculty:** Manages classroom attendance, student details, and notifications.
- **HOD (Admin):** Oversees department performance, manages faculty, and finalizes SSM scores.
- **Principal:** High-level institutional oversight, department management, and final grievance authority.

---

## 🛠 Setup & Running

### Backend Setup
1. **Navigate:** `cd backend_fastapi`
2. **Environment:** Create a `.env` file with `SECRET_KEY` and `TOTP_ENCRYPTION_KEY`.
3. **Initialize:** `python db_setup.py` (Creates tables and initial Principal account).
4. **Run Server:** `uvicorn app.main:app --host 0.0.0.0 --port 8000`

### Frontend Setup
1. **Navigate:** `cd frontend_flutter`
2. **Dependencies:** `flutter pub get`
3. **Run App:** `flutter run`

---

## 📸 Marketing & Assets
The project includes high-fidelity marketing infographics in the `ui/` directory:
- `01_Tech_Stack_Diagram.png`: Architecture overview.
- `02_QR_Attendance_System.png`: End-to-end scanning flow.
- `03_Timetable_Editor.png`: Faculty management view.
- `...` and more (See `ui/` for all 9 standardized light-theme assets).

---

## 🛡 Recent Improvements
- **Security Audit:** Removed hardcoded secrets; enforced environment variables for production.
- **Architecture Cleanup:** Purged legacy SSM models and redundant routes.
- **Standardization:** All UI ad assets updated to a unified 16:9 light-theme infographic style.
- **Optimized Tasks:** Migrated from Celery/Redis to native FastAPI BackgroundTasks for lower resource usage.
