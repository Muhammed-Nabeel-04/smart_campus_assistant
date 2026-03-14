from fastapi import APIRouter
from app.services.chatbot import get_chatbot_response

router = APIRouter(prefix="/chatbot", tags=["Chatbot"])

@router.post("/")
def chatbot(question: str):
    answer = get_chatbot_response(question)
    return {"question": question, "answer": answer}
