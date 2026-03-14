import json
from pathlib import Path
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# Get backend root directory
BASE_DIR = Path(__file__).resolve().parents[2]

# Path to FAQ data
FAQ_PATH = BASE_DIR / "data" / "faq_data.json"

# Load FAQ data
with open(FAQ_PATH, "r", encoding="utf-8") as f:
    faq_data = json.load(f)

questions = [item["question"] for item in faq_data]
answers = [item["answer"] for item in faq_data]

vectorizer = TfidfVectorizer()
question_vectors = vectorizer.fit_transform(questions)

def get_chatbot_response(user_question: str):
    user_vector = vectorizer.transform([user_question])
    similarity = cosine_similarity(user_vector, question_vectors)
    best_match = similarity.argmax()
    return answers[best_match]
