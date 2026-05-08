import json
from datetime import datetime
from app.celery_app import celery_app
from app.database import SessionLocal
from app.models.ssm_proof import SSMProof
from app.services.certificate_verifier import process_certificate

@celery_app.task(name="app.tasks.process_ocr_task")
def process_ocr_task(proof_id: int, file_data_b64: str, file_type: str, criterion_key: str, student_name: str = None):
    db = SessionLocal()
    try:
        # Run the heavy OCR logic
        verification = process_certificate(
            file_data_b64=file_data_b64,
            file_type=file_type,
            criterion_key=criterion_key,
            student_name=student_name,
        )
        
        # Update the proof in DB
        proof = db.query(SSMProof).filter(SSMProof.id == proof_id).first()
        if proof:
            proof.ocr_text = verification.get("ocr_text", "")
            proof.verification_status = verification["status"]
            proof.verification_details = json.dumps({
                "score": verification["score"],
                "checks": verification["checks"],
                "details": verification["details"],
            })
            proof.verified_at = datetime.now()
            db.commit()
            return f"Proof {proof_id} processed: {verification['status']}"
        return f"Proof {proof_id} not found"
        
    except Exception as e:
        print(f"Error processing OCR for proof {proof_id}: {e}")
        # Optionally update status to 'failed' or similar
        proof = db.query(SSMProof).filter(SSMProof.id == proof_id).first()
        if proof:
            proof.verification_status = "review"
            proof.verification_details = json.dumps({"error": str(e), "status": "failed"})
            db.commit()
        return f"Error: {str(e)}"
    finally:
        db.close()
