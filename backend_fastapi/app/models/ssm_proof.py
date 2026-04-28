# File: app/models/ssm_proof.py
# ─────────────────────────────────────────────────────────────────────────────
# SSM Proof — stores uploaded certificate/document for each SSM criterion
# ─────────────────────────────────────────────────────────────────────────────

from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey
from app.database import Base
from datetime import datetime


class SSMProof(Base):
    __tablename__ = "ssm_proofs"

    id              = Column(Integer, primary_key=True, index=True)
    submission_id   = Column(Integer, ForeignKey("ssm_submissions.id"), nullable=False, index=True)
    student_id      = Column(Integer, nullable=False, index=True)

    # Which SSM criterion this proof belongs to
    # e.g. "2_1_nptel", "2_3_internship", "2_4_competition", "2_5_publication"
    criterion_key   = Column(String, nullable=False)
    criterion_label = Column(String, nullable=True)   # Human-readable label

    # File data (base64 encoded — no cloud needed)
    file_name       = Column(String, nullable=False)
    file_type       = Column(String, nullable=False)  # "image" | "pdf"
    file_data       = Column(Text, nullable=False)    # base64 string

    # OCR + Verification
    ocr_text        = Column(Text, nullable=True)     # Raw OCR extracted text
    verification_status  = Column(String, default="pending")
    # pending | valid | review | invalid

    verification_details = Column(Text, nullable=True)  # JSON — what was found/missing
    verified_at     = Column(DateTime, nullable=True)

    uploaded_at     = Column(DateTime, default=datetime.now)
