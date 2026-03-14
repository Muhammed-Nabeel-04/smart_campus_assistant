import pandas as pd
from sklearn.linear_model import LogisticRegression
import joblib
from pathlib import Path

# Get project root (backend/)
BASE_DIR = Path(__file__).resolve().parents[2]

# Correct paths
DATA_PATH = BASE_DIR / "data" / "attendance_data.csv"
MODEL_PATH = BASE_DIR / "ml_models" / "attendance_model.pkl"

# Load data
data = pd.read_csv(DATA_PATH)

X = data[["total_classes", "attended", "percentage"]]
y = data["risk"]

model = LogisticRegression()
model.fit(X, y)

joblib.dump(model, MODEL_PATH)

print("✅ Attendance model trained and saved successfully")
