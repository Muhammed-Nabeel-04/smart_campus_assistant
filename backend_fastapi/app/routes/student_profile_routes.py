from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.services.deps import get_db, get_current_user
from app.models.student import Student
from fastapi import HTTPException

router = APIRouter(prefix="/student", tags=["Student Profile"])


@router.get("/profile/{student_id}")
def get_student_profile(student_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user['role'] == 'student':
        own = db.query(Student).filter(Student.user_id == current_user['user_id']).first()
        if not own or own.id != student_id:
            raise HTTPException(status_code=403, detail="Access denied")
    elif current_user['role'] not in ['faculty', 'admin', 'principal']:
        raise HTTPException(status_code=403, detail="Access denied")

    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    from app.models.department import Department
    dept = db.query(Department).filter(
        Department.code.ilike(student.department)
    ).first()

    return {
        "id": student.id,
        "full_name": student.full_name,
        "register_number": student.register_number,
        "department": dept.name if dept else student.department,
        "year": student.year,
        "section": student.section,
        "email": student.email,
        "phone_number": student.phone_number,
        "date_of_birth": student.date_of_birth,
        "blood_group": student.blood_group,
        "gender": student.gender,
        "residential_type": student.residential_type,
        "address": student.address,
        "parent_name": student.parent_name,
        "parent_phone": student.parent_phone,
        "parent_email": student.parent_email,
        "parent_relationship": student.parent_relationship,
        "hostel_name": student.hostel_name,
        "room_number": student.room_number,
        "emergency_contact_name": student.emergency_contact_name,
        "emergency_contact_phone": student.emergency_contact_phone,
        "medical_conditions": student.medical_conditions,
    }