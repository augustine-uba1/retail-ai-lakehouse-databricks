import os
from enum import Enum
from typing import Any, Dict, List, Optional

from databricks.sdk import WorkspaceClient
from databricks.sdk.service.serving import ChatMessage, ChatMessageRole
from databricks.vector_search.client import VectorSearchClient
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


def classify_question(question: str) -> AgentRoute:
    """
    Simple deterministic router for v1.

    Later, we can replace this with LLM function calling or MCP routing.
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
    if not GENIE_SPACE_ID:
        raise ValueError("GENIE_SPACE_ID is not configured.")

    response = w.genie.start_conversation_and_wait(
        space_id=GENIE_SPACE_ID,
        content=question,
    )

    text_outputs: List[str] = []
    sql_outputs: List[str] = []

    for attachment in response.attachments or []:
        text = getattr(attachment, "text", None)
        if text and getattr(text, "content", None):
            text_outputs.append(text.content)

        query = getattr(attachment, "query", None)
        if query:
            query_text = getattr(query, "query", None)
            if query_text:
                sql_outputs.append(query_text)

    return {
        "conversation_id": response.conversation_id,
        "message_id": response.message_id,
        "text": "\n\n".join(text_outputs).strip(),
        "sql": "\n\n".join(sql_outputs).strip(),
    }


def search_retail_knowledge(question: str, num_results: int = 5) -> List[Dict[str, Any]]:
    if not VECTOR_SEARCH_ENDPOINT_NAME:
        raise ValueError("VECTOR_SEARCH_ENDPOINT_NAME is not configured.")

    if not VECTOR_SEARCH_INDEX_NAME:
        raise ValueError("VECTOR_SEARCH_INDEX_NAME is not configured.")

    vs_client = VectorSearchClient()
    index = vs_client.get_index(
        endpoint_name=VECTOR_SEARCH_ENDPOINT_NAME,
        index_name=VECTOR_SEARCH_INDEX_NAME,
    )

    results = index.similarity_search(
        query_text=question,
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
        query_type="hybrid",
    )

    columns = [
        col["name"]
        for col in results.get("manifest", {}).get("columns", [])
    ]

    rows = results.get("result", {}).get("data_array", [])

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

    return response.choices[0].message.content


def run_retail_agent(question: str) -> AgentResponse:
    route = classify_question(question)

    genie_result: Optional[Dict[str, Any]] = None
    rag_context: Optional[List[Dict[str, Any]]] = None
    tool_trace: List[ToolTrace] = []

    if route in [AgentRoute.GENIE, AgentRoute.BOTH]:
        genie_result = ask_genie(question)
        tool_trace.append(
            ToolTrace(
                tool="genie",
                status="success",
                input=question,
                output_preview=(genie_result.get("text") or "")[:500],
            )
        )

    if route in [AgentRoute.RAG, AgentRoute.BOTH]:
        rag_context = search_retail_knowledge(question)
        rag_preview = "\n".join(
            str(doc.get("chunk_text", ""))[:200]
            for doc in rag_context[:3]
        )
        tool_trace.append(
            ToolTrace(
                tool="vector_search_rag",
                status="success",
                input=question,
                output_preview=rag_preview,
            )
        )

    answer = summarise_with_llm(
        question=question,
        route=route,
        genie_result=genie_result,
        rag_context=rag_context,
    )

    return AgentResponse(
        question=question,
        route=route,
        answer=answer,
        genie_result=genie_result,
        rag_context=rag_context,
        tool_trace=tool_trace,
    )
