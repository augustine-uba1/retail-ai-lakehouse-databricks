-- =========================================================
-- BUILD GOLD TABLES FROM SILVER
-- =========================================================

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.gold.dim_customer')
SELECT
  customer_id,
  customer_name,
  customer_segment,
  city,
  region,
  signup_date
FROM IDENTIFIER({{catalog_name}} || '.silver.customers');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.gold.dim_product')
SELECT
  product_id,
  sku,
  product_name,
  category,
  subcategory,
  brand,
  unit_price,
  cost_price,
  status
FROM IDENTIFIER({{catalog_name}} || '.silver.products');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.gold.dim_store')
SELECT
  store_id,
  store_name,
  city,
  region,
  store_format
FROM IDENTIFIER({{catalog_name}} || '.silver.stores');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.gold.dim_date')
SELECT DISTINCT
  order_date AS date_key,
  year(order_date) AS year,
  quarter(order_date) AS quarter,
  month(order_date) AS month,
  date_format(order_date, 'MMMM') AS month_name,
  weekofyear(order_date) AS week_of_year,
  day(order_date) AS day_of_month
FROM IDENTIFIER({{catalog_name}} || '.silver.sales_orders')
WHERE order_date IS NOT NULL;

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.gold.fact_sales')
SELECT
  so.order_id,
  so.order_date AS sales_date,
  so.customer_id,
  so.product_id,
  so.store_id,
  so.promotion_id,
  so.quantity_sold,
  so.gross_sales_amount,
  so.discount_amount,
  so.net_sales_amount,
  cast(coalesce(r.return_amount, 0.00) AS DECIMAL(12,2)) AS return_amount,
  cast(so.net_sales_amount - coalesce(r.return_amount, 0.00) AS DECIMAL(12,2)) AS net_sales_after_returns_amount
FROM IDENTIFIER({{catalog_name}} || '.silver.sales_orders') so
LEFT JOIN (
  SELECT
    order_id,
    sum(return_amount) AS return_amount
  FROM IDENTIFIER({{catalog_name}} || '.silver.returns')
  GROUP BY order_id
) r
  ON so.order_id = r.order_id;

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.gold.fact_inventory')
SELECT
  inventory_date,
  product_id,
  store_id,
  stock_quantity,
  reorder_threshold,
  is_low_stock
FROM IDENTIFIER({{catalog_name}} || '.silver.inventory');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.gold.fact_returns')
SELECT
  return_id,
  order_id,
  return_date,
  product_id,
  store_id,
  return_reason,
  quantity_returned,
  return_amount
FROM IDENTIFIER({{catalog_name}} || '.silver.returns');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.gold.sales_targets')
SELECT
  target_month,
  store_id,
  product_category,
  sales_target_amount
FROM IDENTIFIER({{catalog_name}} || '.silver.sales_targets');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.gold.customer_feedback_summary')
SELECT
  feedback_date,
  product_id,
  store_id,
  rating,
  sentiment,
  feedback_text
FROM IDENTIFIER({{catalog_name}} || '.silver.customer_feedback');
