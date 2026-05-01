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
