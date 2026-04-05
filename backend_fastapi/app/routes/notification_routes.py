from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from app.services.deps import get_db, get_current_user
from app.models.notification import Notification
from app.models.student import Student

router = APIRouter(prefix="/notifications", tags=["Notifications"])


class PostNotificationRequest(BaseModel):
    title: str
    message: str
    type: str                           # info, warning, urgent, announcement
    target: str                         # all, department, class
    target_class_id: Optional[int] = None
    target_department_id: Optional[int] = None
    sent_by: Optional[int] = None       # faculty_id


# ============================================================================
# POST NOTIFICATION
# ============================================================================

@router.post("/")
def post_notification(
    payload: PostNotificationRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user['role'] not in ['faculty', 'admin']:
        raise HTTPException(status_code=403, detail="Faculty access required")
    notification = Notification(
        title=payload.title,
        message=payload.message,
        type=payload.type,
        target_role=payload.target,
        target_class_id=payload.target_class_id,
        target_department_id=payload.target_department_id,
        sent_by=payload.sent_by,
    )

    db.add(notification)
    db.commit()
    db.refresh(notification)

    return {
        "message": "Notification sent successfully",
        "id": notification.id,
        "title": notification.title,
        "type": notification.type,
    }


# ============================================================================
# GET NOTIFICATIONS FOR STUDENT
# ============================================================================

@router.get("/student/{student_id}")
def get_student_notifications(student_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user['role'] == 'student':
        own = db.query(Student).filter(Student.user_id == current_user['user_id']).first()
        if not own or own.id != student_id:
            raise HTTPException(status_code=403, detail="Access denied")

    # Check student exists
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    # Get student's class info for filtering
    from app.models.department import Department
    from app.models.class_model import ClassModel

    dept = db.query(Department).filter(
        Department.code.ilike(student.department)
    ).first()

    cls = None
    if dept:
        cls = db.query(ClassModel).filter(
            ClassModel.department_id == dept.id,
            ClassModel.year == student.year,
            ClassModel.section == student.section,
        ).first()

    # Build filter — only show notifications relevant to this student
    from sqlalchemy import or_
    filters = [
        Notification.target_role == "all",
        Notification.target_role == "student",
    ]

    # Department-targeted: only if matches student's department
    if dept:
        filters.append(
            (Notification.target_role == "department") &
            (Notification.target_department_id == dept.id)
        )

    # Class-targeted: only if matches student's exact class
    if cls:
        filters.append(
            (Notification.target_role == "class") &
            (Notification.target_class_id == cls.id)
        )

    notifications = db.query(Notification).filter(
        or_(*filters)
    ).order_by(Notification.created_at.desc()).limit(50).all()

    return [
        {
            "id": n.id,
            "title": n.title,
            "message": n.message,
            "type": n.type,
            "created_at": n.created_at.isoformat(),
        }
        for n in notifications
    ]


# ============================================================================
# GET ALL NOTIFICATIONS (for admin/faculty)
# ============================================================================

@router.get("/")
def get_all_notifications(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user['role'] not in ['faculty', 'admin', 'principal']:
        raise HTTPException(status_code=403, detail="Access denied")

    notifications = db.query(Notification).order_by(
        Notification.created_at.desc()
    ).limit(100).all()

    return [
        {
            "id": n.id,
            "title": n.title,
            "message": n.message,
            "type": n.type,
            "target_role": n.target_role,
            "created_at": n.created_at.isoformat(),
        }
        for n in notifications
    ]