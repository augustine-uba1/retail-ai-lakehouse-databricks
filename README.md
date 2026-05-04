# Databricks Retail Sales AI App

## Overview
This project builds a Databricks-native Retail Sales Intelligence platform using Unity Catalog, Delta Lake, AI/BI Genie, Vector Search, Mosaic AI agents, and Databricks Apps.

## Phase 1: Retail Lakehouse Foundation
This phase creates the governed retail lakehouse foundation using a medallion architecture:
- Bronze: raw retail source data
- Silver: cleaned and conformed data
- Gold: business-ready analytics tables
- AI: future RAG and Vector Search tables
- Audit: reconciliation and data quality metrics

## Architecture
Raw files → Bronze → Silver → Gold → Genie / Vector Search / App

## How to deploy
1. Configure Databricks CLI authentication
2. Validate bundle
3. Deploy bundle
4. Run retail lakehouse foundation job

## Key tables
- gold.fact_sales
- gold.dim_product
- gold.dim_store
- gold.dim_customer
- gold.fact_inventory
- gold.fact_returns
- gold.sales_targets

## Next phases
- Phase 2: Databricks and FAST API Setup
- Phase 3: Databricks App shell/FAST API
- Phase 4: Genie Space
- Phase 5: Vector Search RAG
- Phase 6: Agentic orchestration

# Phase 5 Implementation — Create Vector Search for RAG - IMPORTANT NOTE

## Overview

Phase 5 introduces a Retrieval-Augmented Generation (RAG) capability into the Retail AI Databricks App project.

The purpose of this phase is to create a searchable knowledge base that can answer questions using semi-structured and unstructured retail business information such as:

- Return and refund policies
- Product guidance
- Customer feedback
- Promotion rules
- Store operating notes
- Sales playbook guidance

This complements the Genie integration from Phase 4.

Where Genie is used for structured analytics over curated sales data, Vector Search is used to retrieve relevant business context from text-based knowledge sources.

The long-term architecture is:

```text
User Question
    ↓
Databricks App
    ↓
RAG API Endpoint
    ↓
Databricks Vector Search
    ↓
Relevant knowledge chunks
    ↓
LLM-generated answer
```

The original plan was to use Databricks-computed embeddings by creating a Vector Search index with an embedding model endpoint such as:

```text
databricks-gte-large-en
databricks-qwen3-embedding-0-6b
```

However, my current workspace only had the following serving endpoints available:

```text
databricks-gpt-oss-120b
databricks-gpt-oss-20b
databricks-qwen3-next-80b-a3b-instruct
databricks-gemma-3-12b
databricks-meta-llama-3.1-405b-instruct
```

These are chat / instruct / text generation models, not embedding models.

Because no embedding endpoint was available, I have switched to a self-managed embedding approach.

This means:

```text
Text chunks are embedded manually using a notebook and using open source embedding model
    ↓
Embedding vectors are stored in a Delta table
    ↓
Vector Search index is created using the existing vector column
```

**High Level Flow**

```text
Retail knowledge text
    ↓
Clean and chunk text
    ↓
Store chunks in Delta table
    ↓
Generate embeddings using sentence-transformers
    ↓
Store embeddings in ARRAY<FLOAT> column
    ↓
Create Databricks Vector Search Delta Sync Index
    ↓
Query index using embedded user question
```

## Example Questions

The Vector Search index can now answer retrieval-style questions such as:

```text
What is the return policy for damaged electronics?

What does the sales playbook recommend when footwear sales decline?

What are customers saying about running shoe sizing?

Summarise customer feedback about wireless headphones.

What were the terms of the spring footwear promotion?
```

## Future Improvement

Once a Databricks embedding endpoint becomes available in my current workspace, the Vector Search index can be recreated using Databricks-computed embeddings.
If your workspace currently has embedding models available you can use that instead. Databricks documents that these models may are not available to some regions.

Example embedding models endpoint options:

```text
databricks-gte-large-en
databricks-qwen3-embedding-0-6b
BGE Small EN v1.5
GTE Large EN v1.5
```

# Phase 6 target architecture (initial) - IMPORTANT NOTE

This phase now provides 

**Databricks App → Agent layer → Genie for structured analytics + Vector Search for RAG → governed retail data in Unity Catalog.**

Recall, this project uses `Self-managed embedding` RAG using Databricks Vector Search.

The goal was to allow users to ask natural language questions and have the app decide whether to answer using:

1. Databricks Genie
   For structured analytics questions over retail sales data.

1. Databricks Vector Search RAG
   For knowledge-based questions over policy documents, product notes, customer feedback, and playbooks.

1. Both Genie and RAG
   For mixed analytical + contextual questions.

This turns the app from a basic Genie integration into a more intelligent retail assistant.
```text
User question
   |
   v
FastAPI endpoint: /api/agent/ask
   |
   v
Retail Agent Router
   |
   |-- Structured analytics question
   |      -> Databricks Genie
   |
   |-- Policy / document / feedback question
   |      -> Vector Search RAG
   |
   |-- Mixed question
   |      -> Genie + Vector Search RAG
   |
   v
LLM summarisation endpoint
   |
   v
Final business-friendly answer returned to the app
```

### Example Question:
`What were the top 10 products by revenue?`

This gets routed to:
`Genie`

`What does the return policy say about damaged electronics?`

This gets routed to:
`RAG` Because it is asking about policy documentation.

`Why did running shoe sales drop last month, and are customers complaining about sizing?`

This gets routed:
`Both Genie and RAG` Because it needs structured sales data and unstructured customer feedback context.

So, basically for RAG (Retrieval-Augumented Generation) in this project, the process works like this:

1. Retrieve relevant context from a knowledge base.
1. Pass that context to an LLM.
1. Ask the LLM to generate an answer grounded in the retrieved context.

Final Project looks like this:

- Knowledge base:
retail_ai_demo_dev.ai.retail_knowledge_chunks

- Vector Search index:
retail_ai_demo_dev.ai.retail_knowledge_index

- Embedding column:
chunk_vector

- Embedding model:
sentence-transformers/all-MiniLM-L6-v2

- Vector dimension:
384

What does the return policy say about damaged electronics?

The App does this:
1. Takes the user question.
1. Generates a 384-dimensional embedding using all-MiniLM-L6-v2.
1. Sends that embedding as query_vector to Databricks Vector Search.
1. Retrieves the most relevant retail knowledge chunks.
1. Sends the retrieved chunks plus the user question to the LLM.
1. Returns a final answer to the user.

## Important design decision: self-managed embeddings

In Phase 5, I have not use a Databricks-managed embedding endpoint attached to the index.

Instead, I have used a self-managed embedding approach:

```python
model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
vectors = model.encode(texts, normalize_embeddings=True)
```

The generated embeddings were saved into the Delta table column:

```text
chunk_vector
```

Then the Vector Search index was created using:

```python
embedding_dimension=384
embedding_vector_column="chunk_vector"
```

Because of this, the app cannot query the index using only:

```python
query_text=question
```

Instead, the app must generate the query embedding itself and query using:

```python
query_vector=question_vector
```

# Current Agent Tools

The agent currently has two tools:

## Tool 1 — Genie tool

Used for structured questions such as:

```text
What were the top 10 products by revenue?
Which stores missed their sales target?
What was the return rate by category?
Which products had the highest sales last month?
```

The Genie tool calls the configured Databricks Genie Space and returns structured analytics results.

## Tool 2 — Vector Search RAG tool

Used for knowledge/document questions such as:

```text
What does the return policy say about damaged electronics?
What are customers saying about sizing?
What does the sales playbook say about upselling?
What guidance exists for handling product complaints?
```

The RAG tool

```text
1. Embeds the user question.
2. Queries the Vector Search index using query_vector.
3. Retrieves relevant chunks.
4. Sends the chunks to the LLM for final answer generation.
```

## Current API endpoints

The app now has these key endpoints (deployed using FAST API):

```text
GET /api/health
```

Used to check that the app is running and that key environment variables are configured.

```text
GET /api/kpis
```

Returns mocked KPI values for the landing page.

```text
POST /api/chat
```

Initial older Phase 4 Genie-only endpoint (Phase 4, when Genie alone was integrated into the App)

```text
POST /api/agent/ask
```

The new Phase 6 agent endpoint, now the main endpoint, that queries both genie and our vector search.