# Databricks notebook source
# MAGIC %pip install databricks-vectorsearch
# MAGIC dbutils.library.restartPython()

# COMMAND ----------

# DBTITLE 1,create vector search endpoint
from databricks.vector_search.client import VectorSearchClient

vsc = VectorSearchClient()

VECTOR_SEARCH_ENDPOINT_NAME = "retail_ai_vs_endpoint"

vsc.create_endpoint(
    name=VECTOR_SEARCH_ENDPOINT_NAME,
    endpoint_type="STANDARD"
)