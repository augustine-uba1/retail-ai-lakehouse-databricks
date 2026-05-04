import json
import os
from datetime import timedelta
from typing import Any, Optional

from databricks.sdk import WorkspaceClient
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel

from agent import AgentRequest, run_retail_agent

app = FastAPI(
    title="Retail Sales Intelligence App",
    description="Databricks App shell for Genie, RAG, and Agentic AI integration",
    version="0.2.0",
)

app.mount("/static", StaticFiles(directory="static"), name="static")

templates = Jinja2Templates(directory="templates")


class ChatRequest(BaseModel):
    question: str
    conversation_id: Optional[str] = None


def object_to_dict(value: Any) -> dict:
    """
    Convert Databricks SDK response objects into plain Python dictionaries.
    """
    if value is None:
        return {}

    if isinstance(value, dict):
        return value

    if hasattr(value, "as_dict"):
        return value.as_dict()

    try:
        return json.loads(
            json.dumps(
                value,
                default=lambda obj: getattr(obj, "__dict__", str(obj)),
            )
        )
    except Exception:
        return {"raw": str(value)}


def extract_genie_response(message: dict) -> dict:
    """
    Extract text answer, generated SQL and query attachment ID from Genie response.
    """
    attachments = message.get("attachments") or []

    answer_parts = []
    generated_sql = None
    query_attachment_id = None

    for attachment in attachments:
        text_attachment = attachment.get("text")
        query_attachment = attachment.get("query")

        if isinstance(text_attachment, dict):
            content = text_attachment.get("content")
            if content:
                answer_parts.append(content)

        if isinstance(query_attachment, dict):
            generated_sql = (
                query_attachment.get("query")
                or query_attachment.get("sql")
                or query_attachment.get("statement")
            )

            query_attachment_id = (
                attachment.get("attachment_id")
                or attachment.get("id")
            )

    return {
        "answer": "\n\n".join(answer_parts).strip(),
        "sql": generated_sql,
        "query_attachment_id": query_attachment_id,
    }


def ask_genie(question: str, conversation_id: Optional[str] = None) -> dict:
    """
    Send a user question to the configured Databricks Genie Space.
    """
    genie_space_id = os.getenv("GENIE_SPACE_ID")

    if not genie_space_id:
        raise ValueError(
            "GENIE_SPACE_ID is not set. Check app.yaml and the Databricks App Genie resource."
        )

    workspace_client = WorkspaceClient()

    if conversation_id:
        genie_message = workspace_client.genie.create_message_and_wait(
            space_id=genie_space_id,
            conversation_id=conversation_id,
            content=question,
            timeout=timedelta(minutes=10),
        )
    else:
        genie_message = workspace_client.genie.start_conversation_and_wait(
            space_id=genie_space_id,
            content=question,
            timeout=timedelta(minutes=10),
        )

    message = object_to_dict(genie_message)
    parsed = extract_genie_response(message)

    query_result = None

    if parsed.get("query_attachment_id"):
        try:
            result_response = workspace_client.genie.get_message_attachment_query_result(
                space_id=genie_space_id,
                conversation_id=message.get("conversation_id"),
                message_id=message.get("id"),
                attachment_id=parsed["query_attachment_id"],
            )
            query_result = object_to_dict(result_response)
        except Exception as error:
            query_result = {
                "error": f"Genie response was received, but query result retrieval failed: {str(error)}"
            }

    return {
        "question": question,
        "answer": parsed.get("answer") or "Genie returned a response, but no text answer was found.",
        "generated_sql": parsed.get("sql"),
        "query_result": query_result,
        "conversation_id": message.get("conversation_id"),
        "message_id": message.get("id"),
        "status": message.get("status"),
        "source": "databricks_genie",
    }


@app.get("/", response_class=HTMLResponse)
def home(request: Request):
    return templates.TemplateResponse(
        request=request,
        name="index.html",
        context={
            "app_title": "Retail Sales Intelligence",
        },
    )

@app.get("/api/health")
def health_check():
    return {
        "status": "ok",
        "app": "Retail Sales Intelligence App",
        "phase": "Phase 4 - Genie Integration",
        "genie_space_configured": bool(os.getenv("GENIE_SPACE_ID")),
    }


@app.get("/api/kpis")
def get_kpis():
    """
    Temporary mocked KPIs.

    Later this can query Databricks gold tables directly or be replaced
    with a Genie-backed KPI endpoint.
    """
    return {
        "total_sales": "£1.24m",
        "orders": "18,420",
        "returns_rate": "4.8%",
        "low_stock_items": 37,
    }


@app.post("/api/chat")
def chat(chat_request: ChatRequest):
    """
    Phase 4:
    Route structured retail analytics questions to Databricks Genie.
    """
    question = chat_request.question.strip()

    if not question:
        raise HTTPException(status_code=400, detail="Question is required.")

    try:
        return ask_genie(
            question=question,
            conversation_id=chat_request.conversation_id,
        )
    except Exception as error:
        raise HTTPException(status_code=500, detail=str(error))
    
@app.post("/api/agent/ask")
async def ask_retail_agent(payload: AgentRequest):
    try:
        result = run_retail_agent(payload.question)
        return result.model_dump()
    except Exception as e:
        return {
            "error": str(e),
            "question": payload.question,
        }
