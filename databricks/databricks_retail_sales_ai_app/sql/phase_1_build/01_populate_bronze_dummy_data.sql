-- =========================================================
-- POPULATE BRONZE WITH DUMMY RETAIL DATA
-- This script is idempotent because it overwrites the bronze tables.
-- =========================================================

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.bronze.customers_raw')
VALUES
('C001', 'Amara Okafor', 'Premium', 'amara@example.com', 'M1 1AA', 'Manchester', 'North West', DATE '2024-01-12', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('C002', 'James Smith', 'Standard', 'james@example.com', 'L1 2BB', 'Liverpool', 'North West', DATE '2024-02-05', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('C003', 'Sophie Taylor', 'Premium', 'sophie@example.com', 'SW1A 1AA', 'London', 'London', DATE '2024-03-18', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('C004', 'Daniel Brown', 'Standard', 'daniel@example.com', 'B1 1TT', 'Birmingham', 'Midlands', DATE '2024-04-02', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('C005', 'Grace Williams', 'Student', 'grace@example.com', 'LS1 4AB', 'Leeds', 'Yorkshire', DATE '2024-04-22', current_timestamp(), 'dummy_generator', 'phase1_demo');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.bronze.products_raw')
VALUES
('P001', 'SKU-RUN-001', 'Velocity Running Shoes', 'Footwear', 'Running Shoes', 'AeroStep', 89.99, 45.00, DATE '2023-09-01', 'Active', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('P002', 'SKU-JKT-002', 'Urban Winter Jacket', 'Clothing', 'Jackets', 'NorthPeak', 129.99, 70.00, DATE '2023-10-15', 'Active', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('P003', 'SKU-ELE-003', 'Wireless Headphones', 'Electronics', 'Audio', 'SoundMax', 59.99, 30.00, DATE '2023-06-10', 'Active', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('P004', 'SKU-BAG-004', 'Commuter Backpack', 'Accessories', 'Bags', 'CarryPro', 39.99, 18.00, DATE '2023-08-20', 'Active', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('P005', 'SKU-FIT-005', 'Fitness Smart Watch', 'Electronics', 'Wearables', 'FitPulse', 149.99, 85.00, DATE '2024-01-05', 'Active', current_timestamp(), 'dummy_generator', 'phase1_demo');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.bronze.stores_raw')
VALUES
('S001', 'Manchester Arndale', 'Manchester', 'North West', 'Shopping Centre', DATE '2018-05-01', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('S002', 'Liverpool One', 'Liverpool', 'North West', 'High Street', DATE '2019-03-15', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('S003', 'London Oxford Street', 'London', 'London', 'Flagship', DATE '2017-09-12', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('S004', 'Birmingham Bullring', 'Birmingham', 'Midlands', 'Shopping Centre', DATE '2020-01-20', current_timestamp(), 'dummy_generator', 'phase1_demo');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.bronze.promotions_raw')
VALUES
('PR001', 'Spring Running Promo', 'Percentage Discount', 10.00, DATE '2024-03-01', DATE '2024-03-31', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('PR002', 'Electronics Weekend Deal', 'Percentage Discount', 15.00, DATE '2024-04-05', DATE '2024-04-07', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('PR003', 'No Promotion', 'None', 0.00, DATE '2024-01-01', DATE '2024-12-31', current_timestamp(), 'dummy_generator', 'phase1_demo');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.bronze.sales_orders_raw')
VALUES
('O001', DATE '2024-03-05', 'C001', 'P001', 'S001', 'PR001', 2, 89.99, 10.00, current_timestamp(), 'dummy_generator', 'phase1_demo'),
('O002', DATE '2024-03-07', 'C002', 'P001', 'S002', 'PR001', 1, 89.99, 10.00, current_timestamp(), 'dummy_generator', 'phase1_demo'),
('O003', DATE '2024-03-12', 'C003', 'P003', 'S003', 'PR003', 1, 59.99, 0.00, current_timestamp(), 'dummy_generator', 'phase1_demo'),
('O004', DATE '2024-04-03', 'C004', 'P002', 'S004', 'PR003', 1, 129.99, 0.00, current_timestamp(), 'dummy_generator', 'phase1_demo'),
('O005', DATE '2024-04-06', 'C003', 'P005', 'S003', 'PR002', 1, 149.99, 15.00, current_timestamp(), 'dummy_generator', 'phase1_demo'),
('O006', DATE '2024-04-10', 'C001', 'P001', 'S001', 'PR003', 1, 89.99, 0.00, current_timestamp(), 'dummy_generator', 'phase1_demo'),
('O007', DATE '2024-04-12', 'C005', 'P004', 'S002', 'PR003', 2, 39.99, 0.00, current_timestamp(), 'dummy_generator', 'phase1_demo'),
('O008', DATE '2024-04-15', 'C002', 'P003', 'S001', 'PR003', 1, 59.99, 0.00, current_timestamp(), 'dummy_generator', 'phase1_demo');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.bronze.inventory_raw')
VALUES
(DATE '2024-04-30', 'P001', 'S001', 4, 10, current_timestamp(), 'dummy_generator', 'phase1_demo'),
(DATE '2024-04-30', 'P001', 'S002', 6, 10, current_timestamp(), 'dummy_generator', 'phase1_demo'),
(DATE '2024-04-30', 'P002', 'S004', 22, 8, current_timestamp(), 'dummy_generator', 'phase1_demo'),
(DATE '2024-04-30', 'P003', 'S001', 18, 10, current_timestamp(), 'dummy_generator', 'phase1_demo'),
(DATE '2024-04-30', 'P005', 'S003', 3, 7, current_timestamp(), 'dummy_generator', 'phase1_demo'),
(DATE '2024-04-30', 'P004', 'S002', 15, 5, current_timestamp(), 'dummy_generator', 'phase1_demo');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.bronze.returns_raw')
VALUES
('R001', 'O003', DATE '2024-03-18', 'P003', 'S003', 'Faulty item', 1, 59.99, current_timestamp(), 'dummy_generator', 'phase1_demo'),
('R002', 'O004', DATE '2024-04-09', 'P002', 'S004', 'Sizing issue', 1, 129.99, current_timestamp(), 'dummy_generator', 'phase1_demo');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.bronze.sales_targets_raw')
VALUES
(DATE '2024-03-01', 'S001', 'Footwear', 700.00, current_timestamp(), 'dummy_generator', 'phase1_demo'),
(DATE '2024-03-01', 'S002', 'Footwear', 500.00, current_timestamp(), 'dummy_generator', 'phase1_demo'),
(DATE '2024-04-01', 'S001', 'Footwear', 800.00, current_timestamp(), 'dummy_generator', 'phase1_demo'),
(DATE '2024-04-01', 'S003', 'Electronics', 1000.00, current_timestamp(), 'dummy_generator', 'phase1_demo'),
(DATE '2024-04-01', 'S004', 'Clothing', 600.00, current_timestamp(), 'dummy_generator', 'phase1_demo');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.bronze.customer_feedback_raw')
VALUES
('F001', DATE '2024-04-11', 'C001', 'P001', 'S001', 3, 'Running shoes are comfortable but stock was very limited in store.', 'Neutral', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('F002', DATE '2024-04-12', 'C004', 'P002', 'S004', 2, 'Winter jacket sizing runs smaller than expected.', 'Negative', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('F003', DATE '2024-04-13', 'C003', 'P005', 'S003', 5, 'Smart watch is excellent and the promotion made it good value.', 'Positive', current_timestamp(), 'dummy_generator', 'phase1_demo'),
('F004', DATE '2024-04-15', 'C002', 'P003', 'S001', 2, 'Headphones stopped working after a few days.', 'Negative', current_timestamp(), 'dummy_generator', 'phase1_demo');

INSERT OVERWRITE TABLE IDENTIFIER({{catalog_name}} || '.ai.retail_knowledge_chunks')
VALUES
('CH001', 'policy', 'returns_policy', NULL, 'General', NULL, NULL, 'Customers can return faulty electronics within 30 days with proof of purchase.', current_timestamp()),
('CH002', 'product_note', 'running_shoes_notes', 'P001', 'Footwear', NULL, NULL, 'Velocity Running Shoes are designed for everyday runners and perform best when stocked in a full range of sizes.', current_timestamp()),
('CH003', 'sales_playbook', 'upsell_guidance', NULL, 'Accessories', NULL, NULL, 'When selling footwear, recommend socks, backpacks, and fitness wearables as complementary products.', current_timestamp());
