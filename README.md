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
- Phase 2: Databricks App shell
- Phase 3: Genie Space
- Phase 4: Vector Search RAG
- Phase 5: Agentic orchestration

# Phase 5 — Create Vector Search for RAG

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

# Phase 6 target architecture (initial)

```text
User asks question
        |
        v
/api/agent/ask
        |
        v
Agent Router
        |
        |-- analytics question --> Genie
        |
        |-- knowledge question --> Vector Search RAG
        |
        |-- mixed question -----> Genie + Vector Search RAG
        |
        v
LLM summarises final business answer
        |
        v
App displays:
- final answer
- route used
- Genie result
- RAG context
- recommended action
```