# Smart Campus Assistant — Project Documentation

## 📌 Project Overview
The **Smart Campus Assistant** is a comprehensive, multi-role ecosystem designed to digitize and automate college operations. It provides a seamless interface for Students, Faculty (including Class Coordinators), HODs, and the Principal to manage attendance, timetables, grievances, and student performance evaluation.

---

## 🏗 System Architecture

### Backend: FastAPI (Python)
- **Framework:** FastAPI for high-performance asynchronous API endpoints.
- **Database:** SQLite (SQLAlchemy ORM) for localized, efficient data management.
- **Auth:** JWT-based session management with role-based access control (RBAC).
- **Storage:** Base64-encoded file storage within the database to ensure portability and simplicity in campus environments.

### Frontend: Flutter (Dart)
- **Framework:** Flutter for a high-quality, cross-platform mobile experience.
- **Communication:** RESTful API integration via a centralized `ApiService`.
- **UI/UX:** Modern, role-specific dashboards with interactive components like QR scanners and real-time countdown timers.

---

## 🚀 Core Modules

### 1. Attendance Management (QR-Based)
- **Faculty:** Starts an attendance session for a specific class/subject. A dynamic QR code is generated.
- **Student:** Scans the QR code to mark attendance. The system verifies the student's eligibility and location (if enabled).
- **Reports:** Real-time percentage calculation and subject-wise breakdown.

### 2. Digital Timetable
- **Dynamic Scheduling:** Faculty/CC can manage and edit class schedules.
- **Real-time Countdown:** Students see a live countdown to their next class on their dashboard.
- **Blinking Reminders:** Visual cues appear 5 minutes before a class starts to ensure punctuality.

### 3. Complaints & Grievances
- Students can lodge complaints directly through the app.
- **Escalation Logic:** Complaints can be tracked by HODs and escalated to the Principal if unresolved.

### 4. SSM v3 — Student Success Model (The Core Update)
The recently integrated **SSM v3** is an activity-based performance tracking system. Unlike traditional static grading, it evaluates students across five key categories:
- **Category 1: Academic** (GPA, Attendance, Project Status).
- **Category 2: Student Development** (NPTEL, Certifications, Internships).
- **Category 3: Skill & Readiness** (Technical skills, Placement readiness, Innovation).
- **Category 4: Discipline** (Dress code, Punctuality, Social Media contribution).
- **Category 5: Leadership** (Class/College roles, Event management).

**SSM Workflow:**
1. **Activity Submission:** Students upload proofs (Certificates, Photos) for their achievements.
2. **Mentor Review:** The Class Coordinator (CC) reviews and approves/rejects activities.
3. **Scoring Engine:** The system automatically calculates scores and star ratings based on approved activities.
4. **HOD Approval:** The HOD performs a final review and "locks" the score for the academic year.

---

## 🛠 Setup & Running

### Backend Setup
1. **Navigate to backend:** `cd backend_fastapi`
2. **Activate Virtual Env:** `venv\Scripts\activate`
3. **Reset Database (if needed):** `python db_reset.py` (Clears pycache and handles locked database files).
4. **Initialize Database:** `python db_setup.py` (Creates all tables and the initial Principal account).
5. **Run Server:** `uvicorn app.main:app --host 0.0.0.0 --port 8000`

### Frontend Setup
1. **Navigate to frontend:** `cd frontend_flutter`
2. **Install Dependencies:** `flutter pub get`
3. **Run App:** `flutter run`

---

## 🔄 Recent Changes & Improvements
- **SSM v3 Integration:** Fully replaced the old static SSM module with a dynamic, activity-based system.
- **Robust Database Reset:** Updated `db_reset.py` to handle Windows file permission errors and dynamic table cleaning.
- **Surgical Code Fixes:** Updated imports and model references (e.g., `Class` to `ClassModel`) to ensure 100% compatibility between the new SSM module and the existing campus schema.
- **Dashboard Enhancements:** Added direct action buttons for HODs and Mentors to streamline the approval workflow.

---

## 👥 User Roles
- **Student:** Marks attendance, views timetable, submits SSM activities, lodges complaints.
- **Faculty:** Manages attendance, views student details, uploads notices.
- **Mentor (CC):** Approves SSM activities for their assigned class.
- **HOD:** Oversees department-wide performance, manages subjects, finalizes SSM scores.
- **Principal:** System-wide overview, department management, final grievance authority.
