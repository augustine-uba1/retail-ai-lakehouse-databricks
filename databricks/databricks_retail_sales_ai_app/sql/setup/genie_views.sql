-- Databricks notebook source
-- =========================================================
-- PHASE 3: GENIE-FRIENDLY GOLD ANALYTICS VIEWS
-- Catalog: retail_ai_demo_dev
-- Purpose:
-- These views simplify the existing retail gold model for Databricks Genie.
-- Genie should query these views for structured analytics.
-- Replace witrh actual catalog name and run once manually
-- =========================================================


-- =========================================================
-- 1. Sales Performance View
-- =========================================================

CREATE OR REPLACE VIEW retail_ai_demo_dev.gold.vw_genie_sales_performance AS
SELECT
    fs.order_id,
    fs.sales_date,

    CAST(DATE_TRUNC('week', fs.sales_date) AS DATE)  AS sales_week,
    CAST(DATE_TRUNC('month', fs.sales_date) AS DATE) AS sales_month,
    YEAR(fs.sales_date)                              AS sales_year,
    QUARTER(fs.sales_date)                           AS sales_quarter,
    MONTH(fs.sales_date)                             AS sales_month_number,

    fs.customer_id,
    c.customer_name,
    c.customer_segment,
    c.city                                           AS customer_city,
    c.region                                         AS customer_region,

    fs.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,
    p.status                                         AS product_status,

    fs.store_id,
    s.store_name,
    s.city                                           AS store_city,
    s.region                                         AS store_region,
    s.store_format,

    fs.promotion_id,

    fs.quantity_sold,
    fs.gross_sales_amount,
    fs.discount_amount,
    fs.net_sales_amount,
    fs.return_amount,
    fs.net_sales_after_returns_amount,

    p.unit_price                                     AS product_unit_price,
    p.cost_price                                     AS product_cost_price,

    CAST(fs.quantity_sold * p.cost_price AS DECIMAL(12,2)) AS estimated_cost_amount,

    CAST(
        fs.net_sales_after_returns_amount - (fs.quantity_sold * p.cost_price)
        AS DECIMAL(12,2)
    ) AS estimated_margin_amount,

    CASE
        WHEN fs.net_sales_after_returns_amount = 0 THEN NULL
        ELSE CAST(
            (fs.net_sales_after_returns_amount - (fs.quantity_sold * p.cost_price))
            / fs.net_sales_after_returns_amount
            AS DECIMAL(10,4)
        )
    END AS estimated_margin_percentage

FROM retail_ai_demo_dev.gold.fact_sales fs
LEFT JOIN retail_ai_demo_dev.gold.dim_customer c
    ON fs.customer_id = c.customer_id
LEFT JOIN retail_ai_demo_dev.gold.dim_product p
    ON fs.product_id = p.product_id
LEFT JOIN retail_ai_demo_dev.gold.dim_store s
    ON fs.store_id = s.store_id;


COMMENT ON TABLE retail_ai_demo_dev.gold.vw_genie_sales_performance IS
'Business-friendly sales performance view for Genie. Use this for revenue, sales trends, product performance, customer segment analysis, store performance, regional performance, returns impact, and estimated margin analysis.';


-- =========================================================
-- 2. Inventory Position View
-- =========================================================

CREATE OR REPLACE VIEW retail_ai_demo_dev.gold.vw_genie_inventory_position AS
SELECT
    i.inventory_date,

    CAST(DATE_TRUNC('week', i.inventory_date) AS DATE)  AS inventory_week,
    CAST(DATE_TRUNC('month', i.inventory_date) AS DATE) AS inventory_month,
    YEAR(i.inventory_date)                              AS inventory_year,
    QUARTER(i.inventory_date)                           AS inventory_quarter,
    MONTH(i.inventory_date)                             AS inventory_month_number,

    i.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,
    p.status                                            AS product_status,

    i.store_id,
    s.store_name,
    s.city                                              AS store_city,
    s.region                                            AS store_region,
    s.store_format,

    i.stock_quantity,
    i.reorder_threshold,
    i.is_low_stock,

    CASE
        WHEN i.stock_quantity = 0 THEN TRUE
        ELSE FALSE
    END AS is_out_of_stock,

    CASE
        WHEN i.stock_quantity < i.reorder_threshold THEN i.reorder_threshold - i.stock_quantity
        ELSE 0
    END AS stock_shortfall_quantity

FROM retail_ai_demo_dev.gold.fact_inventory i
LEFT JOIN retail_ai_demo_dev.gold.dim_product p
    ON i.product_id = p.product_id
LEFT JOIN retail_ai_demo_dev.gold.dim_store s
    ON i.store_id = s.store_id;


COMMENT ON TABLE retail_ai_demo_dev.gold.vw_genie_inventory_position IS
'Business-friendly inventory view for Genie. Use this for stock levels, low stock products, out-of-stock products, reorder threshold analysis, store inventory, and replenishment risk questions.';


-- =========================================================
-- 3. Returns Analysis View
-- =========================================================

CREATE OR REPLACE VIEW retail_ai_demo_dev.gold.vw_genie_returns_analysis AS
SELECT
    r.return_id,
    r.order_id,
    r.return_date,

    CAST(DATE_TRUNC('week', r.return_date) AS DATE)  AS return_week,
    CAST(DATE_TRUNC('month', r.return_date) AS DATE) AS return_month,
    YEAR(r.return_date)                              AS return_year,
    QUARTER(r.return_date)                           AS return_quarter,
    MONTH(r.return_date)                             AS return_month_number,

    r.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,
    p.status                                         AS product_status,

    r.store_id,
    s.store_name,
    s.city                                           AS store_city,
    s.region                                         AS store_region,
    s.store_format,

    r.return_reason,
    r.quantity_returned,
    r.return_amount

FROM retail_ai_demo_dev.gold.fact_returns r
LEFT JOIN retail_ai_demo_dev.gold.dim_product p
    ON r.product_id = p.product_id
LEFT JOIN retail_ai_demo_dev.gold.dim_store s
    ON r.store_id = s.store_id;


COMMENT ON TABLE retail_ai_demo_dev.gold.vw_genie_returns_analysis IS
'Business-friendly returns view for Genie. Use this for returned products, return reasons, return amount, quantity returned, product return analysis, category return analysis, and store return analysis.';


-- =========================================================
-- 4. Sales Target Performance View
-- =========================================================

CREATE OR REPLACE VIEW retail_ai_demo_dev.gold.vw_genie_sales_target_performance AS
WITH monthly_sales AS (
    SELECT
        CAST(DATE_TRUNC('month', fs.sales_date) AS DATE) AS sales_month,
        fs.store_id,
        p.category AS product_category,
        SUM(fs.net_sales_amount) AS actual_net_sales_amount,
        SUM(fs.net_sales_after_returns_amount) AS actual_net_sales_after_returns_amount
    FROM retail_ai_demo_dev.gold.fact_sales fs
    LEFT JOIN retail_ai_demo_dev.gold.dim_product p
        ON fs.product_id = p.product_id
    GROUP BY
        CAST(DATE_TRUNC('month', fs.sales_date) AS DATE),
        fs.store_id,
        p.category
)

SELECT
    t.target_month,

    YEAR(t.target_month)    AS target_year,
    QUARTER(t.target_month) AS target_quarter,
    MONTH(t.target_month)   AS target_month_number,

    t.store_id,
    s.store_name,
    s.city                  AS store_city,
    s.region                AS store_region,
    s.store_format,

    t.product_category,
    t.sales_target_amount,

    COALESCE(ms.actual_net_sales_amount, 0) AS actual_net_sales_amount,
    COALESCE(ms.actual_net_sales_after_returns_amount, 0) AS actual_net_sales_after_returns_amount,

    COALESCE(ms.actual_net_sales_amount, 0) - t.sales_target_amount AS variance_to_target_amount,

    CASE
        WHEN t.sales_target_amount = 0 THEN NULL
        ELSE CAST(COALESCE(ms.actual_net_sales_amount, 0) / t.sales_target_amount AS DECIMAL(10,4))
    END AS target_attainment_percentage,

    CASE
        WHEN COALESCE(ms.actual_net_sales_amount, 0) >= t.sales_target_amount THEN TRUE
        ELSE FALSE
    END AS has_met_target

FROM retail_ai_demo_dev.gold.sales_targets t
LEFT JOIN monthly_sales ms
    ON t.target_month = ms.sales_month
   AND t.store_id = ms.store_id
   AND t.product_category = ms.product_category
LEFT JOIN retail_ai_demo_dev.gold.dim_store s
    ON t.store_id = s.store_id;


COMMENT ON TABLE retail_ai_demo_dev.gold.vw_genie_sales_target_performance IS
'Business-friendly sales target performance view for Genie. Use this for target attainment, stores missing target, stores exceeding target, category targets, monthly target performance, and variance to target questions.';


-- =========================================================
-- 5. Customer Feedback Summary View
-- =========================================================

CREATE OR REPLACE VIEW retail_ai_demo_dev.gold.vw_genie_customer_feedback_summary AS
SELECT
    f.feedback_date,

    CAST(DATE_TRUNC('week', f.feedback_date) AS DATE)  AS feedback_week,
    CAST(DATE_TRUNC('month', f.feedback_date) AS DATE) AS feedback_month,
    YEAR(f.feedback_date)                              AS feedback_year,
    QUARTER(f.feedback_date)                           AS feedback_quarter,
    MONTH(f.feedback_date)                             AS feedback_month_number,

    f.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,
    p.status                                           AS product_status,

    f.store_id,
    s.store_name,
    s.city                                             AS store_city,
    s.region                                           AS store_region,
    s.store_format,

    f.rating,
    f.sentiment,
    f.feedback_text,

    CASE
        WHEN f.rating >= 4 THEN 'Positive'
        WHEN f.rating = 3 THEN 'Neutral'
        WHEN f.rating <= 2 THEN 'Negative'
        ELSE 'Unknown'
    END AS rating_group

FROM retail_ai_demo_dev.gold.customer_feedback_summary f
LEFT JOIN retail_ai_demo_dev.gold.dim_product p
    ON f.product_id = p.product_id
LEFT JOIN retail_ai_demo_dev.gold.dim_store s
    ON f.store_id = s.store_id;


COMMENT ON TABLE retail_ai_demo_dev.gold.vw_genie_customer_feedback_summary IS
'Business-friendly customer feedback summary view for Genie. Use this for feedback ratings, sentiment analysis, product feedback, store feedback, and customer satisfaction questions.';


-- =========================================================
-- 6. Promotion Performance View
-- Note:
-- There is no gold promotion dimension in the current model.
-- This view uses silver.promotions together with gold.fact_sales.
-- If you want a strict gold-only model later, create gold.dim_promotion.
-- =========================================================

CREATE OR REPLACE VIEW retail_ai_demo_dev.gold.vw_genie_promotion_performance AS
SELECT
    fs.order_id,
    fs.sales_date,

    CAST(DATE_TRUNC('week', fs.sales_date) AS DATE)  AS sales_week,
    CAST(DATE_TRUNC('month', fs.sales_date) AS DATE) AS sales_month,
    YEAR(fs.sales_date)                              AS sales_year,
    QUARTER(fs.sales_date)                           AS sales_quarter,
    MONTH(fs.sales_date)                             AS sales_month_number,

    fs.promotion_id,
    pr.promotion_name,
    pr.promotion_type,
    pr.discount_pct,
    pr.start_date AS promotion_start_date,
    pr.end_date   AS promotion_end_date,

    CASE
        WHEN fs.promotion_id IS NULL OR fs.promotion_id = '' THEN FALSE
        ELSE TRUE
    END AS has_promotion,

    fs.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,

    fs.store_id,
    s.store_name,
    s.city AS store_city,
    s.region AS store_region,
    s.store_format,

    fs.quantity_sold,
    fs.gross_sales_amount,
    fs.discount_amount,
    fs.net_sales_amount,
    fs.return_amount,
    fs.net_sales_after_returns_amount

FROM retail_ai_demo_dev.gold.fact_sales fs
LEFT JOIN retail_ai_demo_dev.silver.promotions pr
    ON fs.promotion_id = pr.promotion_id
LEFT JOIN retail_ai_demo_dev.gold.dim_product p
    ON fs.product_id = p.product_id
LEFT JOIN retail_ai_demo_dev.gold.dim_store s
    ON fs.store_id = s.store_id;


COMMENT ON TABLE retail_ai_demo_dev.gold.vw_genie_promotion_performance IS
'Business-friendly promotion performance view for Genie. Use this for promotion sales, campaign performance, discount analysis, promoted product sales, and revenue generated by promotions.';

-- COMMAND ----------

-- DBTITLE 1,Cell 2
GRANT USE CATALOG ON CATALOG retail_ai_demo_dev
TO `<<REPLACE WITH YOUR APP PRINCIPAL>>`;

GRANT USE SCHEMA ON SCHEMA retail_ai_demo_dev.gold
TO `<<REPLACE WITH YOUR APP PRINCIPAL`;

GRANT SELECT ON VIEW retail_ai_demo_dev.gold.vw_genie_sales_performance
TO `<<REPLACE WITH YOUR APP PRINCIPAL`;

GRANT SELECT ON VIEW retail_ai_demo_dev.gold.vw_genie_inventory_position
TO `<<REPLACE WITH YOUR APP PRINCIPAL`;

GRANT SELECT ON VIEW retail_ai_demo_dev.gold.vw_genie_returns_analysis
TO `<<REPLACE WITH YOUR APP PRINCIPAL`;

GRANT SELECT ON VIEW retail_ai_demo_dev.gold.vw_genie_sales_target_performance
TO `<<REPLACE WITH YOUR APP PRINCIPAL`;

GRANT SELECT ON VIEW retail_ai_demo_dev.gold.vw_genie_customer_feedback_summary
TO `<<REPLACE WITH YOUR APP PRINCIPAL`;

GRANT SELECT ON VIEW retail_ai_demo_dev.gold.vw_genie_promotion_performance
TO `<<REPLACE WITH YOUR APP PRINCIPAL>`;