-- =========================================================
-- BUILD SILVER TABLES FROM BRONZE
-- =========================================================

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.silver.customers')
SELECT
  customer_id,
  initcap(trim(customer_name)) AS customer_name,
  initcap(trim(customer_segment)) AS customer_segment,
  lower(trim(email)) AS email,
  upper(trim(postcode)) AS postcode,
  initcap(trim(city)) AS city,
  initcap(trim(region)) AS region,
  signup_date,
  current_timestamp() AS updated_at
FROM IDENTIFIER({{catalog_name}} || '.bronze.customers_raw')
WHERE customer_id IS NOT NULL;

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.silver.products')
SELECT
  product_id,
  upper(trim(sku)) AS sku,
  initcap(trim(product_name)) AS product_name,
  initcap(trim(category)) AS category,
  initcap(trim(subcategory)) AS subcategory,
  initcap(trim(brand)) AS brand,
  unit_price,
  cost_price,
  launch_date,
  initcap(trim(status)) AS status,
  current_timestamp() AS updated_at
FROM IDENTIFIER({{catalog_name}} || '.bronze.products_raw')
WHERE product_id IS NOT NULL;

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.silver.stores')
SELECT
  store_id,
  initcap(trim(store_name)) AS store_name,
  initcap(trim(city)) AS city,
  initcap(trim(region)) AS region,
  initcap(trim(store_format)) AS store_format,
  opening_date,
  current_timestamp() AS updated_at
FROM IDENTIFIER({{catalog_name}} || '.bronze.stores_raw')
WHERE store_id IS NOT NULL;

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.silver.promotions')
SELECT
  promotion_id,
  initcap(trim(promotion_name)) AS promotion_name,
  initcap(trim(promotion_type)) AS promotion_type,
  coalesce(discount_pct, 0.00) AS discount_pct,
  start_date,
  end_date,
  current_timestamp() AS updated_at
FROM IDENTIFIER({{catalog_name}} || '.bronze.promotions_raw')
WHERE promotion_id IS NOT NULL;

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.silver.sales_orders')
SELECT
  order_id,
  order_date,
  customer_id,
  product_id,
  store_id,
  promotion_id,
  coalesce(quantity_sold, 0) AS quantity_sold,
  coalesce(unit_price, 0.00) AS unit_price,
  coalesce(discount_pct, 0.00) AS discount_pct,
  cast(coalesce(quantity_sold, 0) * coalesce(unit_price, 0.00) AS DECIMAL(12,2)) AS gross_sales_amount,
  cast((coalesce(quantity_sold, 0) * coalesce(unit_price, 0.00)) * (coalesce(discount_pct, 0.00) / 100) AS DECIMAL(12,2)) AS discount_amount,
  cast((coalesce(quantity_sold, 0) * coalesce(unit_price, 0.00)) * (1 - (coalesce(discount_pct, 0.00) / 100)) AS DECIMAL(12,2)) AS net_sales_amount,
  current_timestamp() AS updated_at
FROM IDENTIFIER({{catalog_name}} || '.bronze.sales_orders_raw')
WHERE order_id IS NOT NULL;

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.silver.inventory')
SELECT
  inventory_date,
  product_id,
  store_id,
  coalesce(stock_quantity, 0) AS stock_quantity,
  coalesce(reorder_threshold, 0) AS reorder_threshold,
  coalesce(stock_quantity, 0) < coalesce(reorder_threshold, 0) AS is_low_stock,
  current_timestamp() AS updated_at
FROM IDENTIFIER({{catalog_name}} || '.bronze.inventory_raw')
WHERE product_id IS NOT NULL
  AND store_id IS NOT NULL;

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.silver.returns')
SELECT
  return_id,
  order_id,
  return_date,
  product_id,
  store_id,
  initcap(trim(return_reason)) AS return_reason,
  coalesce(quantity_returned, 0) AS quantity_returned,
  coalesce(return_amount, 0.00) AS return_amount,
  current_timestamp() AS updated_at
FROM IDENTIFIER({{catalog_name}} || '.bronze.returns_raw')
WHERE return_id IS NOT NULL;

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.silver.sales_targets')
SELECT
  target_month,
  store_id,
  initcap(trim(product_category)) AS product_category,
  coalesce(sales_target_amount, 0.00) AS sales_target_amount,
  current_timestamp() AS updated_at
FROM IDENTIFIER({{catalog_name}} || '.bronze.sales_targets_raw')
WHERE target_month IS NOT NULL
  AND store_id IS NOT NULL;

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.silver.customer_feedback')
SELECT
  feedback_id,
  feedback_date,
  customer_id,
  product_id,
  store_id,
  rating,
  trim(feedback_text) AS feedback_text,
  initcap(trim(sentiment)) AS sentiment,
  current_timestamp() AS updated_at
FROM IDENTIFIER({{catalog_name}} || '.bronze.customer_feedback_raw')
WHERE feedback_id IS NOT NULL;