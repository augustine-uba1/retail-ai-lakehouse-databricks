import os
from enum import Enum
from typing import Any, Dict, List, Optional

from databricks.sdk import WorkspaceClient
from databricks.sdk.service.serving import ChatMessage, ChatMessageRole
from pydantic import BaseModel


class AgentRoute(str, Enum):
    GENIE = "genie"
    RAG = "rag"
    BOTH = "both"


class AgentRequest(BaseModel):
    question: str


class ToolTrace(BaseModel):
    tool: str
    status: str
    input: str
    output_preview: Optional[str] = None


class AgentResponse(BaseModel):
    question: str
    route: AgentRoute
    answer: str
    genie_result: Optional[Dict[str, Any]] = None
    rag_context: Optional[List[Dict[str, Any]]] = None
    tool_trace: List[ToolTrace]


w = WorkspaceClient()

GENIE_SPACE_ID = os.getenv("GENIE_SPACE_ID")
VECTOR_SEARCH_ENDPOINT_NAME = os.getenv("VECTOR_SEARCH_ENDPOINT_NAME")
VECTOR_SEARCH_INDEX_NAME = os.getenv("VECTOR_SEARCH_INDEX_NAME")
LLM_ENDPOINT_NAME = os.getenv("LLM_ENDPOINT_NAME", "databricks-gpt-oss-20b")


def _as_dict(obj: Any) -> Dict[str, Any]:
    """
    Convert Databricks SDK objects to dictionaries where possible.

    Some SDK response objects expose .as_dict(), while others expose
    fields as attributes. This helper lets us handle both safely.
    """
    if obj is None:
        return {}

    if isinstance(obj, dict):
        return obj

    if hasattr(obj, "as_dict"):
        try:
            return obj.as_dict()
        except Exception:
            return {}

    return {}


def _get_value(obj: Any, field_name: str, default: Any = None) -> Any:
    """
    Safely read a field from either a dict or an SDK object.
    """
    if obj is None:
        return default

    if isinstance(obj, dict):
        return obj.get(field_name, default)

    return getattr(obj, field_name, default)


def _extract_llm_answer(response: Any) -> str:
    """
    Safely extract text from a Databricks model serving chat response.
    """
    if response is None:
        return "No response returned from the LLM endpoint."

    # Normal SDK object path
    try:
        choices = getattr(response, "choices", None)
        if choices:
            first_choice = choices[0]
            message = getattr(first_choice, "message", None)
            content = getattr(message, "content", None)

            if content:
                return content
    except Exception:
        pass

    # Dict fallback
    response_dict = _as_dict(response)

    try:
        choices = response_dict.get("choices", [])
        if choices:
            message = choices[0].get("message", {})
            content = message.get("content")
            if content:
                return content
    except Exception:
        pass

    return str(response_dict or response)


def classify_question(question: str) -> AgentRoute:
    """
    Simple deterministic router for v1.

    Later, this can be replaced with LLM tool calling or MCP routing.
    """
    q = question.lower()

    analytics_terms = [
        "sales",
        "revenue",
        "orders",
        "target",
        "margin",
        "profit",
        "stock",
        "inventory",
        "return rate",
        "returns",
        "store",
        "region",
        "top",
        "bottom",
        "trend",
        "compare",
        "last month",
        "last week",
        "q1",
        "q2",
        "q3",
        "q4",
        "month",
        "week",
        "quarter",
        "year",
    ]

    knowledge_terms = [
        "policy",
        "procedure",
        "playbook",
        "guidance",
        "faq",
        "complaint",
        "complaints",
        "feedback",
        "customers saying",
        "customer comments",
        "product description",
        "terms",
        "refund",
        "return policy",
        "damaged",
        "electronics",
        "sizing",
    ]

    reasoning_terms = [
        "why",
        "explain",
        "reason",
        "recommend",
        "what should we do",
        "root cause",
        "cause",
    ]

    has_analytics = any(term in q for term in analytics_terms)
    has_knowledge = any(term in q for term in knowledge_terms)
    has_reasoning = any(term in q for term in reasoning_terms)

    if has_analytics and (has_knowledge or has_reasoning):
        return AgentRoute.BOTH

    if has_analytics:
        return AgentRoute.GENIE

    if has_knowledge:
        return AgentRoute.RAG

    # Default to BOTH because broad retail questions often need data + context.
    return AgentRoute.BOTH


def ask_genie(question: str) -> Dict[str, Any]:
    """
    Ask Databricks Genie a structured analytics question.

    This version avoids assuming that GenieMessage always has message_id.
    Some SDK versions expose id instead of message_id.
    """
    if not GENIE_SPACE_ID:
        raise ValueError("GENIE_SPACE_ID is not configured.")

    response = w.genie.start_conversation_and_wait(
        space_id=GENIE_SPACE_ID,
        content=question,
    )

    response_dict = _as_dict(response)

    conversation_id = (
        _get_value(response, "conversation_id")
        or response_dict.get("conversation_id")
    )

    message_id = (
        _get_value(response, "message_id")
        or _get_value(response, "id")
        or response_dict.get("message_id")
        or response_dict.get("id")
    )

    status = (
        _get_value(response, "status")
        or response_dict.get("status")
    )

    attachments = (
        _get_value(response, "attachments")
        or response_dict.get("attachments")
        or []
    )

    text_outputs: List[str] = []
    sql_outputs: List[str] = []

    for attachment in attachments:
        attachment_dict = _as_dict(attachment)

        text_attachment = (
            _get_value(attachment, "text")
            or attachment_dict.get("text")
        )

        query_attachment = (
            _get_value(attachment, "query")
            or attachment_dict.get("query")
        )

        text_content = (
            _get_value(text_attachment, "content")
            or _as_dict(text_attachment).get("content")
        )

        if text_content:
            text_outputs.append(str(text_content))

        sql_query = (
            _get_value(query_attachment, "query")
            or _as_dict(query_attachment).get("query")
        )

        if sql_query:
            sql_outputs.append(str(sql_query))

    return {
        "conversation_id": conversation_id,
        "message_id": message_id,
        "status": str(status) if status else None,
        "text": "\n\n".join(text_outputs).strip(),
        "sql": "\n\n".join(sql_outputs).strip(),
        "raw_response": response_dict,
    }


def search_retail_knowledge(question: str, num_results: int = 5) -> List[Dict[str, Any]]:
    """
    Search the retail knowledge index for RAG context.

    TEMP PHASE 6 FIX:
    The current index is a Direct Vector Access Index without an embedding
    model endpoint, so query_text cannot be used for ANN/vector search.

    For now, use FULL_TEXT search so the app can retrieve matching
    policy/document chunks without needing query_vector.
    """
    if not VECTOR_SEARCH_INDEX_NAME:
        raise ValueError("VECTOR_SEARCH_INDEX_NAME is not configured.")

    results = w.vector_search_indexes.query_index(
        index_name=VECTOR_SEARCH_INDEX_NAME,
        query_text=question,
        query_type="FULL_TEXT",
        columns=[
            "chunk_id",
            "source_type",
            "source_name",
            "product_id",
            "category",
            "store_id",
            "region",
            "chunk_text",
        ],
        num_results=num_results,
    )

    result_dict = _as_dict(results)

    manifest = (
        _get_value(results, "manifest")
        or result_dict.get("manifest")
        or {}
    )

    result_data = (
        _get_value(results, "result")
        or result_dict.get("result")
        or {}
    )

    manifest_dict = _as_dict(manifest)
    result_data_dict = _as_dict(result_data)

    raw_columns = (
        _get_value(manifest, "columns")
        or manifest_dict.get("columns")
        or []
    )

    columns: List[str] = []

    for col in raw_columns:
        col_name = (
            _get_value(col, "name")
            or _as_dict(col).get("name")
        )

        if col_name:
            columns.append(str(col_name))

    rows = (
        _get_value(result_data, "data_array")
        or result_data_dict.get("data_array")
        or []
    )

    documents: List[Dict[str, Any]] = []

    for row in rows:
        item = dict(zip(columns, row))
        documents.append(item)

    return documents


def summarise_with_llm(
    question: str,
    route: AgentRoute,
    genie_result: Optional[Dict[str, Any]],
    rag_context: Optional[List[Dict[str, Any]]],
) -> str:
    """
    Use the configured Databricks model serving endpoint to produce
    a final business-friendly answer.
    """
    context_payload = {
        "route": route.value,
        "genie_result": genie_result,
        "rag_context": rag_context,
    }

    system_prompt = """
You are a Retail Sales Intelligence Agent.

You answer business questions using:
1. Genie results for structured analytics.
2. Vector Search RAG context for policies, product knowledge, customer feedback, and playbooks.

Rules:
- Be concise but useful.
- Do not invent numbers.
- If the Genie result does not contain a metric, say that the available data does not show it.
- If RAG context is limited, say that only limited supporting context was found.
- If the question is about policy, customer feedback, product documentation, or playbooks, rely mainly on RAG context.
- Structure the answer as:
  1. Direct answer
  2. Evidence
  3. Recommended action
"""

    user_prompt = f"""
User question:
{question}

Tool route used:
{route.value}

Tool outputs:
{context_payload}

Now produce the final business-friendly answer.
"""

    response = w.serving_endpoints.query(
        name=LLM_ENDPOINT_NAME,
        messages=[
            ChatMessage(
                role=ChatMessageRole.SYSTEM,
                content=system_prompt,
            ),
            ChatMessage(
                role=ChatMessageRole.USER,
                content=user_prompt,
            ),
        ],
        max_tokens=900,
        temperature=0.1,
    )

    return _extract_llm_answer(response)


def run_retail_agent(question: str) -> AgentResponse:
    """
    Main Phase 6 agent orchestration function.

    It decides which tool to use, calls Genie and/or Vector Search,
    then asks the LLM endpoint to produce the final answer.
    """
    cleaned_question = question.strip()

    if not cleaned_question:
        raise ValueError("Question is required.")

    route = classify_question(cleaned_question)

    genie_result: Optional[Dict[str, Any]] = None
    rag_context: Optional[List[Dict[str, Any]]] = None
    tool_trace: List[ToolTrace] = []

    if route in [AgentRoute.GENIE, AgentRoute.BOTH]:
        genie_result = ask_genie(cleaned_question)

        genie_preview = (
            genie_result.get("text")
            or genie_result.get("sql")
            or "Genie returned a response, but no text or SQL preview was available."
        )

        tool_trace.append(
            ToolTrace(
                tool="genie",
                status="success",
                input=cleaned_question,
                output_preview=str(genie_preview)[:500],
            )
        )

    if route in [AgentRoute.RAG, AgentRoute.BOTH]:
        rag_context = search_retail_knowledge(cleaned_question)

        if rag_context:
            rag_preview = "\n".join(
                str(doc.get("chunk_text", ""))[:200]
                for doc in rag_context[:3]
            )
        else:
            rag_preview = "No matching RAG context returned from Vector Search."

        tool_trace.append(
            ToolTrace(
                tool="vector_search_rag",
                status="success",
                input=cleaned_question,
                output_preview=rag_preview,
            )
        )

    answer = summarise_with_llm(
        question=cleaned_question,
        route=route,
        genie_result=genie_result,
        rag_context=rag_context,
    )

    return AgentResponse(
        question=cleaned_question,
        route=route,
        answer=answer,
        genie_result=genie_result,
        rag_context=rag_context,
        tool_trace=tool_trace,
    )
