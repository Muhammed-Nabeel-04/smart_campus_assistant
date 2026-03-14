from fastapi import APIRouter, HTTPException
import joblib
from pathlib import Path

router = APIRouter(prefix="/predict", tags=["Attendance Prediction"])

BASE_DIR = Path(__file__).resolve().parents[2]
MODEL_PATH = BASE_DIR / "ml_models" / "attendance_model.pkl"

try:
    model = joblib.load(MODEL_PATH)
except Exception as e:
    model = None

@router.post("/")
def predict_attendance(total_classes: int, attended: int):
    if model is None:
        raise HTTPException(status_code=500, detail="Model not loaded")

    if attended > total_classes:
        raise HTTPException(status_code=400, detail="Attended cannot exceed total classes")

    percentage = round((attended / total_classes) * 100, 2)

    prediction = model.predict([[total_classes, attended, percentage]])[0]

    status_map = {
        0: "SAFE",
        1: "WARNING",
        2: "CRITICAL"
    }

    return {
        "attendance_percentage": percentage,
        "risk_status": status_map[prediction]
    }
