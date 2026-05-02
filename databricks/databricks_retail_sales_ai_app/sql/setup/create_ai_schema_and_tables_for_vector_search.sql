-- Databricks notebook source
CREATE SCHEMA IF NOT EXISTS retail_ai_demo_dev.ai;

-- This table becomes your RAG knowledge base. 
-- For now, we will use demo retail knowledge instead of loading PDFs.

CREATE OR REPLACE TABLE retail_ai_demo_dev.ai.retail_knowledge_chunks (
    chunk_id STRING NOT NULL,
    source_type STRING,
    source_name STRING,
    doc_title STRING,
    product_id STRING,
    sku STRING,
    category STRING,
    store_id STRING,
    region STRING,
    chunk_text STRING,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
USING DELTA
TBLPROPERTIES (
    delta.enableChangeDataFeed = true
);


-- COMMAND ----------

-- This script Insert sample retail knowledge chunks into the ai.retail_knowledge_chunks table.
-- In a real scenario, you would replace this with logic to ingest
-- and chunk documents like product manuals, store policies, training materials, etc.

INSERT INTO retail_ai_demo_dev.ai.retail_knowledge_chunks
VALUES
(
  'chunk_policy_001',
  'policy',
  'retail_returns_policy',
  'Retail Returns and Refund Policy',
  NULL,
  NULL,
  'Electronics',
  NULL,
  NULL,
  'Electronics can be returned within 30 days of purchase if the product is faulty, damaged on arrival, or not as described. Customers must provide proof of purchase. Opened electronics can only be refunded if a fault is confirmed.',
  current_timestamp(),
  current_timestamp()
),
(
  'chunk_policy_002',
  'policy',
  'retail_returns_policy',
  'Retail Returns and Refund Policy',
  NULL,
  NULL,
  'Clothing',
  NULL,
  NULL,
  'Clothing items can be returned within 28 days if unworn, unused, and returned with original tags. Items with hygiene seals removed are not eligible for return unless faulty.',
  current_timestamp(),
  current_timestamp()
),
(
  'chunk_playbook_001',
  'sales_playbook',
  'store_sales_playbook',
  'Store Sales Playbook',
  NULL,
  NULL,
  'Footwear',
  NULL,
  NULL,
  'When footwear sales decline, store managers should check stock availability, recent promotion changes, local competitor pricing, customer sizing complaints, and whether popular sizes are missing from inventory.',
  current_timestamp(),
  current_timestamp()
),
(
  'chunk_feedback_001',
  'customer_feedback',
  'customer_feedback_q1',
  'Customer Feedback Summary Q1',
  'P1001',
  'RUN-SHOE-001',
  'Footwear',
  'S001',
  'North West',
  'Several customers complained that the running shoes fit smaller than expected. Common feedback mentioned tight sizing, discomfort during long walks, and difficulty choosing the right size online.',
  current_timestamp(),
  current_timestamp()
),
(
  'chunk_feedback_002',
  'customer_feedback',
  'customer_feedback_q1',
  'Customer Feedback Summary Q1',
  'P2001',
  'ELEC-HEAD-001',
  'Electronics',
  'S002',
  'London',
  'Customers praised the wireless headphones for battery life and sound quality, but some reported Bluetooth pairing issues after firmware updates.',
  current_timestamp(),
  current_timestamp()
),
(
  'chunk_promo_001',
  'promotion_terms',
  'spring_promotion_terms',
  'Spring Promotion Terms',
  NULL,
  NULL,
  'Footwear',
  NULL,
  'North West',
  'The spring footwear promotion offered 10 percent off selected running shoes between 1 March and 31 March. The promotion excluded clearance items and could not be combined with loyalty vouchers.',
  current_timestamp(),
  current_timestamp()
);
