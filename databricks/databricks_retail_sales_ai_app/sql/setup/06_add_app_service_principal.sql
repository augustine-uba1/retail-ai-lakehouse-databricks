-- Databricks notebook source
-- DBTITLE 1,APP SERVICE PRINCIPAL PERMISSIONS
-- =========================================================
-- PHASE 6 APP SERVICE PRINCIPAL PERMISSIONS
-- Catalog: retail_ai_demo_dev
-- Principal: Databricks App service principal App ID
-- =========================================================

-- Replace this with your actual Databricks App service principal App ID.
-- Keep the backticks.
-- Example:
-- `00000000-0000-0000-0000-000000000000`


-- =========================================================
-- 1. Allow the app service principal to see/use the catalog
-- =========================================================

GRANT USE CATALOG
ON CATALOG `retail_ai_demo_dev`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;


-- =========================================================
-- 2. Allow the app service principal to use the gold schema
-- Genie queries your curated analytics views/tables here
-- =========================================================

GRANT USE SCHEMA
ON SCHEMA `retail_ai_demo_dev`.`gold`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;


-- Grant SELECT on all current and future gold objects via schema-level inheritance.
-- This covers the Genie-friendly views such as:
-- retail_ai_demo_dev.gold.vw_genie_sales_performance
-- retail_ai_demo_dev.gold.vw_genie_inventory_position
-- retail_ai_demo_dev.gold.vw_genie_returns_analysis
-- retail_ai_demo_dev.gold.vw_genie_promotion_performance

GRANT SELECT
ON SCHEMA `retail_ai_demo_dev`.`gold`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;


-- =========================================================
-- 3. Allow the app service principal to use the ai schema
-- Vector Search index and RAG chunk/source tables live here
-- =========================================================

GRANT USE SCHEMA
ON SCHEMA `retail_ai_demo_dev`.`ai`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;


GRANT SELECT
ON SCHEMA `retail_ai_demo_dev`.`ai`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;

-- COMMAND ----------

-- DBTITLE 1,More locked-down version
-- =========================================================
-- Minimum catalog/schema access
-- =========================================================

GRANT USE CATALOG
ON CATALOG `retail_ai_demo_dev`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;

GRANT USE SCHEMA
ON SCHEMA `retail_ai_demo_dev`.`gold`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;

GRANT USE SCHEMA
ON SCHEMA `retail_ai_demo_dev`.`ai`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;


-- =========================================================
-- Grant access only to Genie-facing gold views
-- Replace/add/remove view names based on your actual objects
-- =========================================================

GRANT SELECT
ON VIEW `retail_ai_demo_dev`.`gold`.`vw_genie_sales_performance`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;

GRANT SELECT
ON VIEW `retail_ai_demo_dev`.`gold`.`vw_genie_inventory_position`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;

GRANT SELECT
ON VIEW `retail_ai_demo_dev`.`gold`.`vw_genie_returns_analysis`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;

GRANT SELECT
ON VIEW `retail_ai_demo_dev`.`gold`.`vw_genie_promotion_performance`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;


-- =========================================================
-- Grant access to the RAG source table
-- Replace table name if yours is different
-- =========================================================

GRANT SELECT
ON TABLE `retail_ai_demo_dev`.`ai`.`retail_knowledge_chunks`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;


-- =========================================================
-- Grant access to the Vector Search index
-- Replace index name if yours is different
-- Vector Search indexes are Unity Catalog objects/table-like resources.
-- =========================================================

GRANT SELECT
ON TABLE `retail_ai_demo_dev`.`ai`.`retail_knowledge_index`
TO `<APP_SERVICE_PRINCIPAL_APP_ID>`;