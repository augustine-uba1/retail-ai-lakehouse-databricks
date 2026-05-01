-- =========================================================
-- VALIDATE PHASE 1 LAKEHOUSE BUILD
-- Writes results into audit.phase1_validation_results
-- Fails the job if any critical validation fails.
-- =========================================================

TRUNCATE TABLE IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results');

INSERT INTO IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results')
SELECT
  current_timestamp(),
  'bronze_customers_has_rows',
  'row_count',
  CASE WHEN count(*) > 0 THEN 'PASS' ELSE 'FAIL' END,
  count(*),
  'count > 0',
  'Bronze customers table should contain rows'
FROM IDENTIFIER({{catalog_name}} || '.bronze.customers_raw');

INSERT INTO IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results')
SELECT
  current_timestamp(),
  'bronze_sales_orders_has_rows',
  'row_count',
  CASE WHEN count(*) > 0 THEN 'PASS' ELSE 'FAIL' END,
  count(*),
  'count > 0',
  'Bronze sales orders table should contain rows'
FROM IDENTIFIER({{catalog_name}} || '.bronze.sales_orders_raw');

INSERT INTO IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results')
SELECT
  current_timestamp(),
  'silver_sales_orders_has_rows',
  'row_count',
  CASE WHEN count(*) > 0 THEN 'PASS' ELSE 'FAIL' END,
  count(*),
  'count > 0',
  'Silver sales orders table should contain rows'
FROM IDENTIFIER({{catalog_name}} || '.silver.sales_orders');

INSERT INTO IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results')
SELECT
  current_timestamp(),
  'gold_fact_sales_has_rows',
  'row_count',
  CASE WHEN count(*) > 0 THEN 'PASS' ELSE 'FAIL' END,
  count(*),
  'count > 0',
  'Gold fact_sales table should contain rows'
FROM IDENTIFIER({{catalog_name}} || '.gold.fact_sales');

INSERT INTO IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results')
SELECT
  current_timestamp(),
  'gold_fact_sales_has_valid_customers',
  'referential_integrity',
  CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
  count(*),
  'missing_customer_count = 0',
  'Every sales record should have a matching customer'
FROM IDENTIFIER({{catalog_name}} || '.gold.fact_sales') fs
LEFT JOIN IDENTIFIER({{catalog_name}} || '.gold.dim_customer') dc
  ON fs.customer_id = dc.customer_id
WHERE dc.customer_id IS NULL;

INSERT INTO IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results')
SELECT
  current_timestamp(),
  'gold_fact_sales_has_valid_products',
  'referential_integrity',
  CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
  count(*),
  'missing_product_count = 0',
  'Every sales record should have a matching product'
FROM IDENTIFIER({{catalog_name}} || '.gold.fact_sales') fs
LEFT JOIN IDENTIFIER({{catalog_name}} || '.gold.dim_product') dp
  ON fs.product_id = dp.product_id
WHERE dp.product_id IS NULL;

INSERT INTO IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results')
SELECT
  current_timestamp(),
  'gold_fact_sales_has_valid_stores',
  'referential_integrity',
  CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
  count(*),
  'missing_store_count = 0',
  'Every sales record should have a matching store'
FROM IDENTIFIER({{catalog_name}} || '.gold.fact_sales') fs
LEFT JOIN IDENTIFIER({{catalog_name}} || '.gold.dim_store') ds
  ON fs.store_id = ds.store_id
WHERE ds.store_id IS NULL;

INSERT INTO IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results')
SELECT
  current_timestamp(),
  'gold_fact_sales_net_amount_not_null',
  'data_quality',
  CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
  count(*),
  'null_net_sales_amount_count = 0',
  'Net sales amount should not be null'
FROM IDENTIFIER({{catalog_name}} || '.gold.fact_sales')
WHERE net_sales_amount IS NULL;

INSERT INTO IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results')
SELECT
  current_timestamp(),
  'gold_inventory_low_stock_records_exist',
  'business_signal',
  CASE WHEN count(*) > 0 THEN 'PASS' ELSE 'WARN' END,
  count(*),
  'low_stock_count > 0',
  'Demo data should include at least one low stock product for later AI demo scenarios'
FROM IDENTIFIER({{catalog_name}} || '.gold.fact_inventory')
WHERE is_low_stock = true;

-- Return validation results for visibility.
SELECT *
FROM IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results')
ORDER BY validation_run_timestamp, validation_name;

-- Fail the job if any critical validation failed.
SELECT
  CASE
    WHEN count(*) > 0 THEN raise_error(concat('Phase 1 validation failed. Failed checks: ', count(*)))
    ELSE 'Phase 1 validation passed'
  END AS validation_outcome
FROM IDENTIFIER({{catalog_name}} || '.audit.phase1_validation_results')
WHERE status = 'FAIL';
