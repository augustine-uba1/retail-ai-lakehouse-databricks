# Databricks notebook source
# DBTITLE 1,embedding column
# MAGIC %sql
# MAGIC ALTER TABLE retail_ai_demo_dev.ai.retail_knowledge_chunks
# MAGIC ADD COLUMNS (chunk_vector ARRAY<FLOAT>);

# COMMAND ----------

# MAGIC %md
# MAGIC ## self-managed embeddings.
# MAGIC ## below steps Generate embeddings

# COMMAND ----------

# DBTITLE 1,usimg a lightweight open-source embedding model from sentence-transformers
# MAGIC %pip install -U sentence-transformers
# MAGIC dbutils.library.restartPython()

# COMMAND ----------

## This model creates 384-dimensional vectors, 
## so our Vector Search index will use: embedding_dimension=384
from sentence_transformers import SentenceTransformer
from pyspark.sql import functions as F
from pyspark.sql.types import ArrayType, FloatType

CATALOG = "retail_ai_demo_dev"
SCHEMA = "ai"
TABLE_NAME = "retail_knowledge_chunks"
FULL_TABLE_NAME = f"{CATALOG}.{SCHEMA}.{TABLE_NAME}"

# Lightweight embedding model for demo use
model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")

# Read chunk table
df = spark.table(FULL_TABLE_NAME)

# Pull small demo data to driver
pdf = df.select(
    "chunk_id",
    "chunk_text"
).toPandas()

# Generate vectors
texts = pdf["chunk_text"].fillna("").tolist()
vectors = model.encode(texts, normalize_embeddings=True)

pdf["chunk_vector"] = [
    [float(x) for x in vector]
    for vector in vectors
]

embedding_df = spark.createDataFrame(pdf[["chunk_id", "chunk_vector"]])

embedding_df.createOrReplaceTempView("embedding_updates")

# COMMAND ----------

# DBTITLE 1,Update the Delta table with embeddings
spark.sql(f"""
MERGE INTO {FULL_TABLE_NAME} AS target
USING embedding_updates AS source
ON target.chunk_id = source.chunk_id
WHEN MATCHED THEN
  UPDATE SET target.chunk_vector = source.chunk_vector
""")

# COMMAND ----------

# DBTITLE 1,vector_dimension should be equal to 384 for each for
display(
    spark.sql(f"""
    SELECT
        chunk_id,
        source_type,
        doc_title,
        size(chunk_vector) AS vector_dimension,
        chunk_text
    FROM {FULL_TABLE_NAME}
    """)
)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Below steps now creates the Vector Search index using self-managed embeddings from above

# COMMAND ----------

# MAGIC %pip install databricks-vectorsearch
# MAGIC dbutils.library.restartPython()

# COMMAND ----------

# This follows Databricks-supported self-managed embedding pattern.

from databricks.vector_search.client import VectorSearchClient

vsc = VectorSearchClient()

VECTOR_SEARCH_ENDPOINT_NAME = "retail_ai_vs_endpoint"
SOURCE_TABLE_NAME = "retail_ai_demo_dev.ai.retail_knowledge_chunks"
INDEX_NAME = "retail_ai_demo_dev.ai.retail_knowledge_index"

index = vsc.create_delta_sync_index(
    endpoint_name=VECTOR_SEARCH_ENDPOINT_NAME,
    source_table_name=SOURCE_TABLE_NAME,
    index_name=INDEX_NAME,
    pipeline_type="TRIGGERED",
    primary_key="chunk_id",
    embedding_dimension=384,
    embedding_vector_column="chunk_vector",
    columns_to_sync=[
        "chunk_id",
        "source_type",
        "source_name",
        "doc_title",
        "product_id",
        "sku",
        "category",
        "store_id",
        "region",
        "chunk_text"
    ]
)

# COMMAND ----------

# DBTITLE 1,Sync the indexSync the index
# you many need to wait for some minutes for the index from above to be Provisioned
# before running this cell, if not you get an error
# BadRequest: Vector index retail_ai_demo_dev.ai.retail_knowledge_index is not ready
index.sync()

# COMMAND ----------

# DBTITLE 1,Test - Query the index
from databricks.vector_search.client import VectorSearchClient
from sentence_transformers import SentenceTransformer

vsc = VectorSearchClient()

INDEX_NAME = "retail_ai_demo_dev.ai.retail_knowledge_index"

index = vsc.get_index(index_name=INDEX_NAME)

model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")

question = "What is the return policy for damaged electronics?"

question_vector = model.encode(
    question,
    normalize_embeddings=True
).tolist()

question_vector = [float(x) for x in question_vector]

results = index.similarity_search(
    query_vector=question_vector,
    columns=[
        "chunk_id",
        "source_type",
        "doc_title",
        "category",
        "region",
        "chunk_text"
    ],
    num_results=3
)

display(results)

# COMMAND ----------

# MAGIC %md
# MAGIC The below uses index to Python to create the Index, documentation link below allows to create using the databricks UI as well.
# MAGIC [Create vector search endpoints and indexes ](https://learn.microsoft.com/en-us/azure/databricks/vector-search/create-vector-search)