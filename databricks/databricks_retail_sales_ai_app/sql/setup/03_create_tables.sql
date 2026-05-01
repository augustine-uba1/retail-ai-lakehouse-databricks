-- =========================================================
-- BRONZE TABLES
-- =========================================================

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.bronze.customers_raw') (
  customer_id STRING,
  customer_name STRING,
  customer_segment STRING,
  email STRING,
  postcode STRING,
  city STRING,
  region STRING,
  signup_date DATE,
  ingestion_timestamp TIMESTAMP,
  source_system STRING,
  batch_id STRING
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.bronze.products_raw') (
  product_id STRING,
  sku STRING,
  product_name STRING,
  category STRING,
  subcategory STRING,
  brand STRING,
  unit_price DECIMAL(10,2),
  cost_price DECIMAL(10,2),
  launch_date DATE,
  status STRING,
  ingestion_timestamp TIMESTAMP,
  source_system STRING,
  batch_id STRING
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.bronze.stores_raw') (
  store_id STRING,
  store_name STRING,
  city STRING,
  region STRING,
  store_format STRING,
  opening_date DATE,
  ingestion_timestamp TIMESTAMP,
  source_system STRING,
  batch_id STRING
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.bronze.promotions_raw') (
  promotion_id STRING,
  promotion_name STRING,
  promotion_type STRING,
  discount_pct DECIMAL(5,2),
  start_date DATE,
  end_date DATE,
  ingestion_timestamp TIMESTAMP,
  source_system STRING,
  batch_id STRING
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.bronze.sales_orders_raw') (
  order_id STRING,
  order_date DATE,
  customer_id STRING,
  product_id STRING,
  store_id STRING,
  promotion_id STRING,
  quantity_sold INT,
  unit_price DECIMAL(10,2),
  discount_pct DECIMAL(5,2),
  ingestion_timestamp TIMESTAMP,
  source_system STRING,
  batch_id STRING
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.bronze.inventory_raw') (
  inventory_date DATE,
  product_id STRING,
  store_id STRING,
  stock_quantity INT,
  reorder_threshold INT,
  ingestion_timestamp TIMESTAMP,
  source_system STRING,
  batch_id STRING
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.bronze.returns_raw') (
  return_id STRING,
  order_id STRING,
  return_date DATE,
  product_id STRING,
  store_id STRING,
  return_reason STRING,
  quantity_returned INT,
  return_amount DECIMAL(10,2),
  ingestion_timestamp TIMESTAMP,
  source_system STRING,
  batch_id STRING
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.bronze.sales_targets_raw') (
  target_month DATE,
  store_id STRING,
  product_category STRING,
  sales_target_amount DECIMAL(12,2),
  ingestion_timestamp TIMESTAMP,
  source_system STRING,
  batch_id STRING
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.bronze.customer_feedback_raw') (
  feedback_id STRING,
  feedback_date DATE,
  customer_id STRING,
  product_id STRING,
  store_id STRING,
  rating INT,
  feedback_text STRING,
  sentiment STRING,
  ingestion_timestamp TIMESTAMP,
  source_system STRING,
  batch_id STRING
)
USING DELTA;


-- =========================================================
-- SILVER TABLES
-- =========================================================

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.silver.customers') (
  customer_id STRING,
  customer_name STRING,
  customer_segment STRING,
  email STRING,
  postcode STRING,
  city STRING,
  region STRING,
  signup_date DATE,
  updated_at TIMESTAMP
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.silver.products') (
  product_id STRING,
  sku STRING,
  product_name STRING,
  category STRING,
  subcategory STRING,
  brand STRING,
  unit_price DECIMAL(10,2),
  cost_price DECIMAL(10,2),
  launch_date DATE,
  status STRING,
  updated_at TIMESTAMP
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.silver.stores') (
  store_id STRING,
  store_name STRING,
  city STRING,
  region STRING,
  store_format STRING,
  opening_date DATE,
  updated_at TIMESTAMP
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.silver.promotions') (
  promotion_id STRING,
  promotion_name STRING,
  promotion_type STRING,
  discount_pct DECIMAL(5,2),
  start_date DATE,
  end_date DATE,
  updated_at TIMESTAMP
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.silver.sales_orders') (
  order_id STRING,
  order_date DATE,
  customer_id STRING,
  product_id STRING,
  store_id STRING,
  promotion_id STRING,
  quantity_sold INT,
  unit_price DECIMAL(10,2),
  discount_pct DECIMAL(5,2),
  gross_sales_amount DECIMAL(12,2),
  discount_amount DECIMAL(12,2),
  net_sales_amount DECIMAL(12,2),
  updated_at TIMESTAMP
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.silver.inventory') (
  inventory_date DATE,
  product_id STRING,
  store_id STRING,
  stock_quantity INT,
  reorder_threshold INT,
  is_low_stock BOOLEAN,
  updated_at TIMESTAMP
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.silver.returns') (
  return_id STRING,
  order_id STRING,
  return_date DATE,
  product_id STRING,
  store_id STRING,
  return_reason STRING,
  quantity_returned INT,
  return_amount DECIMAL(10,2),
  updated_at TIMESTAMP
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.silver.sales_targets') (
  target_month DATE,
  store_id STRING,
  product_category STRING,
  sales_target_amount DECIMAL(12,2),
  updated_at TIMESTAMP
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.silver.customer_feedback') (
  feedback_id STRING,
  feedback_date DATE,
  customer_id STRING,
  product_id STRING,
  store_id STRING,
  rating INT,
  feedback_text STRING,
  sentiment STRING,
  updated_at TIMESTAMP
)
USING DELTA;


-- =========================================================
-- GOLD TABLES
-- =========================================================

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.gold.dim_customer') (
  customer_id STRING,
  customer_name STRING,
  customer_segment STRING,
  city STRING,
  region STRING,
  signup_date DATE
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.gold.dim_product') (
  product_id STRING,
  sku STRING,
  product_name STRING,
  category STRING,
  subcategory STRING,
  brand STRING,
  unit_price DECIMAL(10,2),
  cost_price DECIMAL(10,2),
  status STRING
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.gold.dim_store') (
  store_id STRING,
  store_name STRING,
  city STRING,
  region STRING,
  store_format STRING
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.gold.dim_date') (
  date_key DATE,
  year INT,
  quarter INT,
  month INT,
  month_name STRING,
  week_of_year INT,
  day_of_month INT
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.gold.fact_sales') (
  order_id STRING,
  sales_date DATE,
  customer_id STRING,
  product_id STRING,
  store_id STRING,
  promotion_id STRING,
  quantity_sold INT,
  gross_sales_amount DECIMAL(12,2),
  discount_amount DECIMAL(12,2),
  net_sales_amount DECIMAL(12,2),
  return_amount DECIMAL(12,2),
  net_sales_after_returns_amount DECIMAL(12,2)
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.gold.fact_inventory') (
  inventory_date DATE,
  product_id STRING,
  store_id STRING,
  stock_quantity INT,
  reorder_threshold INT,
  is_low_stock BOOLEAN
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.gold.fact_returns') (
  return_id STRING,
  order_id STRING,
  return_date DATE,
  product_id STRING,
  store_id STRING,
  return_reason STRING,
  quantity_returned INT,
  return_amount DECIMAL(10,2)
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.gold.sales_targets') (
  target_month DATE,
  store_id STRING,
  product_category STRING,
  sales_target_amount DECIMAL(12,2)
)
USING DELTA;

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.gold.customer_feedback_summary') (
  feedback_date DATE,
  product_id STRING,
  store_id STRING,
  rating INT,
  sentiment STRING,
  feedback_text STRING
)
USING DELTA;


-- =========================================================
-- AI PLACEHOLDER TABLE
-- This will be useful later for Vector Search/RAG.
-- =========================================================

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.ai.retail_knowledge_chunks') (
  chunk_id STRING,
  source_type STRING,
  source_name STRING,
  product_id STRING,
  category STRING,
  store_id STRING,
  region STRING,
  chunk_text STRING,
  created_at TIMESTAMP
)
USING DELTA;


-- =========================================================
-- AUDIT TABLE
-- =========================================================

CREATE OR REPLACE TABLE IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results') (
  validation_run_timestamp TIMESTAMP,
  validation_name STRING,
  validation_category STRING,
  status STRING,
  actual_value BIGINT,
  expected_condition STRING,
  validation_message STRING
)
USING DELTA;