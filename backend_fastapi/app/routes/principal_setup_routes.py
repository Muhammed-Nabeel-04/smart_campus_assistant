# File: app/routes/principal_setup_routes.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List
from passlib.context import CryptContext

from app.services.deps import get_db, get_current_user
from app.models.user import User
from app.models.department import Department

router = APIRouter(prefix="/principal/setup", tags=["Principal Setup"])

bcrypt = CryptContext(schemes=["bcrypt"])

# ============================================================================
# CHECK SETUP STATUS
# ============================================================================

@router.get("/status")
def check_setup_status(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Check if principal has completed initial setup"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    # Check if departments exist
    departments_exist = db.query(Department).count() > 0
    
    # Get principal user
    user = db.query(User).filter(User.id == current_user['user_id']).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check if password is still default
    # You might want to add a flag in User model like `setup_completed`
    password_changed = True  # Assume changed if they logged in
    
    setup_completed = departments_exist
    
    return {
        "setup_completed": setup_completed,
        "departments_added": departments_exist,
        "department_count": db.query(Department).count()
    }


# ============================================================================
# CHANGE PRINCIPAL PASSWORD
# ============================================================================

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


@router.post("/change-password")
def change_principal_password(
    payload: ChangePasswordRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Principal changes their password"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    # Get user
    user = db.query(User).filter(User.id == current_user['user_id']).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Verify current password
    if not bcrypt.verify(payload.current_password, user.password):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    
    # Hash and update password
    user.password = bcrypt.hash(payload.new_password)
    
    db.commit()
    
    return {"message": "Password changed successfully"}


# ============================================================================
# BATCH CREATE DEPARTMENTS
# ============================================================================

class DepartmentCreate(BaseModel):
    name: str
    code: str


class BatchDepartmentsRequest(BaseModel):
    departments: List[DepartmentCreate]


@router.post("/departments/batch")
def create_departments_batch(
    payload: BatchDepartmentsRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create multiple departments in one request (for principal setup)"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    created_departments = []
    errors = []
    
    for dept_data in payload.departments:
        # Check if department already exists
        existing = db.query(Department).filter(
            (Department.name == dept_data.name) | (Department.code == dept_data.code)
        ).first()
        
        if existing:
            errors.append(f"Department {dept_data.name} ({dept_data.code}) already exists")
            continue
        
        # Create new department
        new_dept = Department(
            name=dept_data.name,
            code=dept_data.code,
            created_by_principal_id=current_user['user_id']
        )
        
        db.add(new_dept)
        created_departments.append(new_dept)
    
    db.commit()
    
    return {
        "message": f"Created {len(created_departments)} departments",
        "count": len(created_departments),
        "errors": errors if errors else None
    }


# ============================================================================
# UPDATE EMAIL
# ============================================================================

class UpdateEmailRequest(BaseModel):
    new_email: str
    password: str  # Require password for security


@router.post("/change-email")
def change_principal_email(
    payload: UpdateEmailRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Principal changes their email"""
    
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")
    
    # Get user
    user = db.query(User).filter(User.id == current_user['user_id']).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Verify password
    if not bcrypt.verify(payload.password, user.password):
        raise HTTPException(status_code=400, detail="Password is incorrect")
    
    # Check if email already exists
    existing = db.query(User).filter(User.email == payload.new_email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already in use")
    
    # Update email
    user.email = payload.new_email
    
    db.commit()
    
    return {"message": "Email changed successfully", "new_email": payload.new_email}
