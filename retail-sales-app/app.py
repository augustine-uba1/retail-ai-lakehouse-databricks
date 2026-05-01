from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel


app = FastAPI(
    title="Retail Sales Intelligence App",
    description="Databricks App shell for Genie, RAG, and Agentic AI integration",
    version="0.1.0",
)

app.mount("/static", StaticFiles(directory="static"), name="static")

templates = Jinja2Templates(directory="templates")


class ChatRequest(BaseModel):
    question: str


@app.get("/", response_class=HTMLResponse)
def home(request: Request):
    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "app_title": "Retail Sales Intelligence",
        },
    )


@app.get("/api/health")
def health_check():
    return {
        "status": "ok",
        "app": "Retail Sales Intelligence App",
        "phase": "Phase 2 - App Shell",
    }


@app.get("/api/kpis")
def get_kpis():
    """
    Temporary mocked KPIs for Phase 2.

    Later, this can query Databricks gold tables using:
    - Databricks SQL Warehouse
    - Databricks SDK
    - Unity Catalog governed tables
    """
    return {
        "total_sales": "£1.24m",
        "orders": "18,420",
        "returns_rate": "4.8%",
        "low_stock_items": 37,
    }


@app.post("/api/chat")
def chat_placeholder(chat_request: ChatRequest):
    """
    Temporary placeholder endpoint.

    Later phases:
    - Phase 4: route structured questions to Genie
    - Phase 5: route document/context questions to Vector Search RAG
    - Phase 6: route mixed questions to the agentic process
    """
    return {
        "question": chat_request.question,
        "answer": (
            "This is a Phase 2 placeholder response. "
            "In later phases, this will connect to Genie, Vector Search RAG, "
            "and the retail AI agent."
        ),
        "source": "mock_app_shell",
    }