# File: app/routes/principal_routes.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from passlib.context import CryptContext
from datetime import datetime, timedelta
import uuid

from app.services.deps import get_db, get_current_user
from app.models.user import User
from app.models.department import Department
from app.models.faculty import Faculty
from app.models.onboarding_token import OnboardingToken

router = APIRouter(prefix="/principal", tags=["Principal Management"])

bcrypt = CryptContext(schemes=["bcrypt"])

# ============================================================================
# DASHBOARD STATS
# ============================================================================

@router.get("/stats")
def get_principal_stats(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get dashboard statistics for principal"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    total_departments = db.query(Department).count()
    total_hods = db.query(User).filter(User.role == "admin").count()
    total_faculty = db.query(User).filter(User.role == "faculty").count()
    total_students = db.query(User).filter(User.role == "student").count()
    
    # Departments without HODs
    depts_without_hod = db.query(Department).filter(Department.hod_user_id == None).count()
    
    return {
        "total_departments": total_departments,
        "total_hods": total_hods,
        "total_faculty": total_faculty,
        "total_students": total_students,
        "departments_without_hod": depts_without_hod
    }


# ============================================================================
# DEPARTMENT MANAGEMENT
# ============================================================================

@router.get("/departments")
def get_all_departments(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all departments"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    departments = db.query(Department).all()
    
    result = []
    for dept in departments:
        hod_info = None
        if dept.hod_user_id:
            hod_user = db.query(User).filter(User.id == dept.hod_user_id).first()
            if hod_user:
                hod_info = {
                    "id": hod_user.id,
                    "name": hod_user.name,
                    "email": hod_user.email
                }
        
        result.append({
            "id": dept.id,
            "name": dept.name,
            "code": dept.code,
            "hod": hod_info,
            "created_at": dept.created_at.isoformat() if dept.created_at else None
        })
    
    return result


class DepartmentCreateRequest(BaseModel):
    name: str
    code: str


@router.post("/departments")
def create_department(
    payload: DepartmentCreateRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a single department"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    # Check if already exists
    existing = db.query(Department).filter(
        (Department.name == payload.name) | (Department.code == payload.code)
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="Department already exists")
    
    new_dept = Department(
        name=payload.name,
        code=payload.code,
        created_by_principal_id=current_user['user_id']
    )
    
    db.add(new_dept)
    db.commit()
    db.refresh(new_dept)
    
    return {
        "id": new_dept.id,
        "name": new_dept.name,
        "code": new_dept.code,
        "message": "Department created successfully"
    }


class DepartmentUpdateRequest(BaseModel):
    name: Optional[str] = None
    code: Optional[str] = None


@router.put("/departments/{department_id}")
def update_department(
    department_id: int,
    payload: DepartmentUpdateRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update department"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    dept = db.query(Department).filter(Department.id == department_id).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    
    if payload.name:
        dept.name = payload.name
    if payload.code:
        dept.code = payload.code
    
    db.commit()
    db.refresh(dept)
    
    return {
        "id": dept.id,
        "name": dept.name,
        "code": dept.code,
        "message": "Department updated successfully"
    }


@router.delete("/departments/{department_id}")
def delete_department(
    department_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete department"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    dept = db.query(Department).filter(Department.id == department_id).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    
    # TODO: Check if department has students/faculty before deleting
    
    db.delete(dept)
    db.commit()
    
    return {"message": "Department deleted successfully"}


# ============================================================================
# HOD MANAGEMENT
# ============================================================================

@router.get("/hods")
def get_all_hods(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all HODs"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    hods = db.query(User).filter(User.role == "admin").all()
    
    result = []
    for hod in hods:
        # Find department assigned to this HOD
        dept = db.query(Department).filter(Department.hod_user_id == hod.id).first()
        
        result.append({
            "id": hod.id,
            "name": hod.name,
            "email": hod.email,
            "department": {
                "id": dept.id,
                "name": dept.name,
                "code": dept.code
            } if dept else None,
            "created_at": hod.created_at.isoformat() if hod.created_at else None
        })
    
    return result


class HODCreateRequest(BaseModel):
    name: str
    email: str
    department_id: int
    employee_id: Optional[str] = None
    phone_number: Optional[str] = None


@router.post("/hods")
def create_hod(
    payload: HODCreateRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create HOD account"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    # Check if email already exists
    existing_user = db.query(User).filter(User.email == payload.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already exists")
    
    # Check if department exists
    dept = db.query(Department).filter(Department.id == payload.department_id).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    
    # Check if department already has a HOD
    if dept.hod_user_id:
        raise HTTPException(status_code=400, detail="Department already has a HOD")
    
    # Create user with role 'admin' (HOD)
    # Password will be set during onboarding
    new_user = User(
        name=payload.name,
        email=payload.email,
        password="",  # Will be set via QR onboarding
        role="admin"
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Assign HOD to department
    dept.hod_user_id = new_user.id
    db.commit()
    
    faculty = Faculty(
        user_id=new_user.id,
        full_name=payload.name,
        employee_id=payload.employee_id or f"HOD{dept.code}",
        department=dept.code,
        email=payload.email,
        phone_number=payload.phone_number or ""
    )
    db.add(faculty)
    db.commit()
    
    return {
        "id": new_user.id,
        "name": new_user.name,
        "email": new_user.email,
        "department_id": payload.department_id,
        "message": "HOD created successfully. Generate QR for onboarding."
    }


class HODUpdateRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    department_id: Optional[int] = None
    phone_number: Optional[str] = None


@router.put("/hods/{hod_id}")
def update_hod(
    hod_id: int,
    payload: HODUpdateRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update HOD"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    user = db.query(User).filter(User.id == hod_id, User.role == "admin").first()
    if not user:
        raise HTTPException(status_code=404, detail="HOD not found")
    
    if payload.name:
        user.name = payload.name
    if payload.email:
        # Check if new email exists
        existing = db.query(User).filter(User.email == payload.email, User.id != hod_id).first()
        if existing:
            raise HTTPException(status_code=400, detail="Email already in use")
        user.email = payload.email
    
    if payload.department_id:
        # Update department assignment
        # Remove from old department
        old_dept = db.query(Department).filter(Department.hod_user_id == hod_id).first()
        if old_dept:
            old_dept.hod_user_id = None
        
        # Assign to new department
        new_dept = db.query(Department).filter(Department.id == payload.department_id).first()
        if not new_dept:
            raise HTTPException(status_code=404, detail="Department not found")
        if new_dept.hod_user_id and new_dept.hod_user_id != hod_id:
            raise HTTPException(status_code=400, detail="Department already has a HOD")
        new_dept.hod_user_id = hod_id
    
    db.commit()
    db.refresh(user)
    
    return {"message": "HOD updated successfully"}


@router.delete("/hods/{hod_id}")
def delete_hod(
    hod_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete HOD"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    user = db.query(User).filter(User.id == hod_id, User.role == "admin").first()
    if not user:
        raise HTTPException(status_code=404, detail="HOD not found")
    
    # Remove from department
    dept = db.query(Department).filter(Department.hod_user_id == hod_id).first()
    if dept:
        dept.hod_user_id = None
    
    # Delete faculty record
    faculty = db.query(Faculty).filter(Faculty.user_id == hod_id).first()
    if faculty:
        db.delete(faculty)
    
    # Delete user
    db.delete(user)
    db.commit()
    
    return {"message": "HOD deleted successfully"}


@router.post("/hods/{hod_id}/generate-qr")
def generate_hod_qr(
    hod_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Generate onboarding QR for HOD"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    user = db.query(User).filter(User.id == hod_id, User.role == "admin").first()
    if not user:
        raise HTTPException(status_code=404, detail="HOD not found")
    
    # Generate token
    token = str(uuid.uuid4())
    expiry = datetime.utcnow() + timedelta(minutes=5)
    
    onboarding_token = OnboardingToken(
        token=token,
        role="admin",  # HOD role
        target_id=hod_id,
        expiry_time=expiry
    )
    
    db.add(onboarding_token)
    db.commit()
    
    return {
        "token": token,
        "hod_id": hod_id,
        "hod_name": user.name,
        "expires_at": expiry.isoformat(),
        "expires_in_minutes": 5
    }
