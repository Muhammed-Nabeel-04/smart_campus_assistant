import qrcode
import uuid
from datetime import datetime, timedelta
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
QR_DIR = BASE_DIR / "data" / "qr_codes"
QR_DIR.mkdir(parents=True, exist_ok=True)

def generate_qr_payload(session_id: int, token: str):
    return {
        "session_id": session_id,
        "token": token
    }

def generate_qr_image(payload: dict):
    qr = qrcode.make(payload)
    filename = f"qr_{payload['session_id']}.png"
    path = QR_DIR / filename
    qr.save(path)
    return str(path)
