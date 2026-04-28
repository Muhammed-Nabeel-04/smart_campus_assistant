# File: app/routes/ssm_proof_routes.py
# ─────────────────────────────────────────────────────────────────────────────
# SSM Proof Routes — file upload, OCR verification, fetch proofs
# Prefix: /ssm/proofs
# ─────────────────────────────────────────────────────────────────────────────

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import json

from app.services.deps import get_db, get_current_user
from app.models.ssm_proof import SSMProof
from app.models.ssm import SSMSubmission
from app.models.student import Student
from app.services.certificate_verifier import process_certificate

router = APIRouter(prefix="/ssm/proofs", tags=["SSM Proofs"])


# ── Which criteria require proof uploads ──────────────────────────────────────
PROOF_CRITERIA = {
    "2_1_nptel":       "NPTEL / SWAYAM Certificate",
    "2_2_online_cert": "Industry Online Certification",
    "2_3_internship":  "Internship / In-plant Training Certificate",
    "2_4_competition": "Technical Competition / Hackathon Certificate",
    "2_5_publication": "Publication / Patent Document",
    "1_6_project":     "Project Completion Certificate / Report",
    "2_6_skill_programs": "Professional Skill Program Certificate",
}


# ============================================================================
# SCHEMAS
# ============================================================================

class UploadProofRequest(BaseModel):
    submission_id: int
    criterion_key: str       # e.g. "2_1_nptel"
    file_name: str
    file_type: str           # "image" | "pdf"
    file_data: str           # base64 encoded


class VerifyProofRequest(BaseModel):
    proof_id: int


# ============================================================================
# 1. UPLOAD PROOF + AUTO-VERIFY
# ============================================================================

@router.post("/upload")
def upload_proof(
    payload: UploadProofRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """
    Upload a certificate/document for a specific SSM criterion.
    Automatically runs OCR + rule-based verification.
    """
    # Validate submission exists
    sub = db.query(SSMSubmission).filter(
        SSMSubmission.id == payload.submission_id
    ).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Submission not found")

    if sub.status not in ["draft", "mentor_rejected"]:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot upload proof — submission status is '{sub.status}'"
        )

    # Validate criterion key
    if payload.criterion_key not in PROOF_CRITERIA:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid criterion key. Valid keys: {list(PROOF_CRITERIA.keys())}"
        )

    # Validate file type
    if payload.file_type not in ["image", "pdf"]:
        raise HTTPException(status_code=400, detail="file_type must be 'image' or 'pdf'")

    # Validate base64 is not empty / too large (max ~5MB)
    if not payload.file_data:
        raise HTTPException(status_code=400, detail="file_data is empty")
    if len(payload.file_data) > 7_000_000:  # ~5MB in base64
        raise HTTPException(status_code=400, detail="File too large. Max 5MB.")

    # Get student name for name matching
    student = db.query(Student).filter(Student.id == sub.student_id).first()
    student_name = student.full_name if student else None

    # Run OCR + verification
    try:
        verification = process_certificate(
            file_data_b64=payload.file_data,
            file_type=payload.file_type,
            criterion_key=payload.criterion_key,
            student_name=student_name,
        )
    except Exception as e:
        verification = {
            "status": "review",
            "score": 0,
            "checks": {},
            "details": f"Verification failed: {str(e)}",
            "ocr_text": "",
        }

    # Check if a proof already exists for this criterion — replace it
    existing = db.query(SSMProof).filter(
        SSMProof.submission_id == payload.submission_id,
        SSMProof.criterion_key == payload.criterion_key,
    ).first()

    if existing:
        existing.file_name = payload.file_name
        existing.file_type = payload.file_type
        existing.file_data = payload.file_data
        existing.ocr_text = verification.get("ocr_text", "")
        existing.verification_status = verification["status"]
        existing.verification_details = json.dumps({
            "score": verification["score"],
            "checks": verification["checks"],
            "details": verification["details"],
        })
        existing.verified_at = datetime.now()
        existing.uploaded_at = datetime.now()
        db.commit()
        proof = existing
    else:
        proof = SSMProof(
            submission_id=payload.submission_id,
            student_id=sub.student_id,
            criterion_key=payload.criterion_key,
            criterion_label=PROOF_CRITERIA.get(payload.criterion_key),
            file_name=payload.file_name,
            file_type=payload.file_type,
            file_data=payload.file_data,
            ocr_text=verification.get("ocr_text", ""),
            verification_status=verification["status"],
            verification_details=json.dumps({
                "score": verification["score"],
                "checks": verification["checks"],
                "details": verification["details"],
            }),
            verified_at=datetime.now(),
        )
        db.add(proof)
        db.commit()
        db.refresh(proof)

    return {
        "message": "Proof uploaded and verified",
        "proof_id": proof.id,
        "criterion_key": proof.criterion_key,
        "criterion_label": proof.criterion_label,
        "file_name": proof.file_name,
        "verification_status": proof.verification_status,
        "verification_score": verification["score"],
        "verification_details": verification["details"],
        "checks": verification["checks"],
    }


# ============================================================================
# 2. RE-VERIFY AN EXISTING PROOF
# ============================================================================

@router.post("/verify/{proof_id}")
def reverify_proof(
    proof_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Re-run verification on an existing proof (e.g. after manual override)."""
    proof = db.query(SSMProof).filter(SSMProof.id == proof_id).first()
    if not proof:
        raise HTTPException(status_code=404, detail="Proof not found")

    student = db.query(Student).filter(Student.id == proof.student_id).first()
    student_name = student.full_name if student else None

    verification = process_certificate(
        file_data_b64=proof.file_data,
        file_type=proof.file_type,
        criterion_key=proof.criterion_key,
        student_name=student_name,
    )

    proof.ocr_text = verification.get("ocr_text", "")
    proof.verification_status = verification["status"]
    proof.verification_details = json.dumps({
        "score": verification["score"],
        "checks": verification["checks"],
        "details": verification["details"],
    })
    proof.verified_at = datetime.now()
    db.commit()

    return {
        "proof_id": proof.id,
        "verification_status": proof.verification_status,
        "verification_score": verification["score"],
        "verification_details": verification["details"],
        "checks": verification["checks"],
    }


# ============================================================================
# 3. GET ALL PROOFS FOR A SUBMISSION
# ============================================================================

@router.get("/submission/{submission_id}")
def get_proofs(
    submission_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get all uploaded proofs for a submission (without file data for speed)."""
    proofs = db.query(SSMProof).filter(
        SSMProof.submission_id == submission_id
    ).all()

    result = []
    for p in proofs:
        details = {}
        try:
            if p.verification_details:
                details = json.loads(p.verification_details)
        except Exception:
            pass

        result.append({
            "id": p.id,
            "criterion_key": p.criterion_key,
            "criterion_label": p.criterion_label,
            "file_name": p.file_name,
            "file_type": p.file_type,
            "verification_status": p.verification_status,
            "verification_score": details.get("score", 0),
            "verification_details": details.get("details", ""),
            "checks": details.get("checks", {}),
            "uploaded_at": p.uploaded_at.isoformat() if p.uploaded_at else None,
        })

    return result


# ============================================================================
# 4. GET SINGLE PROOF WITH FILE DATA (for viewing/downloading)
# ============================================================================

@router.get("/{proof_id}/file")
def get_proof_file(
    proof_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get proof including base64 file data — for preview/download."""
    proof = db.query(SSMProof).filter(SSMProof.id == proof_id).first()
    if not proof:
        raise HTTPException(status_code=404, detail="Proof not found")

    details = {}
    try:
        if proof.verification_details:
            details = json.loads(proof.verification_details)
    except Exception:
        pass

    return {
        "id": proof.id,
        "criterion_key": proof.criterion_key,
        "criterion_label": proof.criterion_label,
        "file_name": proof.file_name,
        "file_type": proof.file_type,
        "file_data": proof.file_data,  # base64
        "verification_status": proof.verification_status,
        "verification_score": details.get("score", 0),
        "verification_details": details.get("details", ""),
        "ocr_text": proof.ocr_text,
        "uploaded_at": proof.uploaded_at.isoformat() if proof.uploaded_at else None,
    }


# ============================================================================
# 5. MANUAL OVERRIDE (Faculty/HOD can manually set status)
# ============================================================================

class ManualOverrideRequest(BaseModel):
    status: str     # valid | review | invalid
    remarks: Optional[str] = None


@router.put("/{proof_id}/override")
def manual_override(
    proof_id: int,
    payload: ManualOverrideRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Faculty/HOD can manually override the verification status."""
    if current_user["role"] not in ["faculty", "admin", "principal"]:
        raise HTTPException(status_code=403, detail="Only faculty/HOD can override")

    if payload.status not in ["valid", "review", "invalid"]:
        raise HTTPException(status_code=400, detail="Status must be valid, review, or invalid")

    proof = db.query(SSMProof).filter(SSMProof.id == proof_id).first()
    if not proof:
        raise HTTPException(status_code=404, detail="Proof not found")

    # Update with manual override
    existing_details = {}
    try:
        if proof.verification_details:
            existing_details = json.loads(proof.verification_details)
    except Exception:
        pass

    existing_details["manual_override"] = True
    existing_details["override_by"] = current_user["user_id"]
    existing_details["override_remarks"] = payload.remarks
    existing_details["override_at"] = datetime.now().isoformat()

    proof.verification_status = payload.status
    proof.verification_details = json.dumps(existing_details)
    proof.verified_at = datetime.now()
    db.commit()

    return {
        "message": f"Proof status manually set to '{payload.status}'",
        "proof_id": proof.id,
        "new_status": proof.verification_status,
    }


# ============================================================================
# 6. DELETE PROOF
# ============================================================================

@router.delete("/{proof_id}")
def delete_proof(
    proof_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    proof = db.query(SSMProof).filter(SSMProof.id == proof_id).first()
    if not proof:
        raise HTTPException(status_code=404, detail="Proof not found")

    # Check submission is still editable
    sub = db.query(SSMSubmission).filter(
        SSMSubmission.id == proof.submission_id
    ).first()
    if sub and sub.status not in ["draft", "mentor_rejected"]:
        raise HTTPException(
            status_code=400,
            detail="Cannot delete proof after submission"
        )

    db.delete(proof)
    db.commit()
    return {"message": "Proof deleted"}


# ============================================================================
# 7. GET ALL PROOFS FOR REVIEW (Faculty/HOD)
# ============================================================================

@router.get("/review/all")
def get_all_proofs_for_review(
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get all proofs — for faculty/HOD to review uploaded certificates."""
    if current_user["role"] not in ["faculty", "admin", "principal"]:
        raise HTTPException(status_code=403, detail="Access denied")

    query = db.query(SSMProof)
    if status:
        query = query.filter(SSMProof.verification_status == status)

    proofs = query.order_by(SSMProof.id.desc()).all()
    result = []

    for p in proofs:
        details = {}
        try:
            if p.verification_details:
                details = json.loads(p.verification_details)
        except Exception:
            pass

        student = db.query(Student).filter(Student.id == p.student_id).first()

        result.append({
            "id": p.id,
            "submission_id": p.submission_id,
            "student_name": student.full_name if student else "Unknown",
            "register_number": student.register_number if student else "",
            "criterion_key": p.criterion_key,
            "criterion_label": p.criterion_label,
            "file_name": p.file_name,
            "file_type": p.file_type,
            "verification_status": p.verification_status,
            "verification_score": details.get("score", 0),
            "verification_details": details.get("details", ""),
            "checks": details.get("checks", {}),
            "uploaded_at": p.uploaded_at.isoformat() if p.uploaded_at else None,
        })

    return result
