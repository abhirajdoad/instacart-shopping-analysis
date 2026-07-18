-- =============================================================
-- 03_build_order_baskets.sql
-- Build one row per order with KNOWN basket contents.
--
-- Output tables
--   category_map   : aisle_id -> analysis category
--   order_baskets  : one row per prior/train order with item counts,
--                    distinct aisles and items per category
--
-- 'test' orders are dropped automatically because they have no rows
-- in order_products_prior / order_products_train.
-- =============================================================

-- -------------------------------------------------------------
-- 1. Category definitions (Instacart's own aisle classification)
--    Organic and non-organic products are NOT separated.
-- -------------------------------------------------------------
DROP TABLE IF EXISTS category_map;
CREATE TABLE category_map AS
SELECT aisle_id,
       aisle,
       CASE
           WHEN aisle_id = 86                     THEN 'eggs'          -- eggs
           WHEN aisle_id = 84                     THEN 'milk'          -- milk
           WHEN aisle_id = 120                    THEN 'yogurt'        -- yogurt
           WHEN aisle_id IN (35, 49)              THEN 'poultry'       -- poultry counter, packaged poultry
           WHEN aisle_id IN (39, 15)              THEN 'seafood'       -- seafood counter, packaged seafood
           WHEN aisle_id IN (24, 83, 123)         THEN 'fresh_produce' -- fresh fruits, fresh vegetables,
                                                                       -- packaged vegetables fruits
           WHEN aisle_id IN (45, 50, 61, 78,
                             107, 117, 125)       THEN 'snacks'        -- all 7 aisles of the snacks department
       END AS category
FROM aisles;

-- -------------------------------------------------------------
-- 2. One row per order with known basket contents
-- -------------------------------------------------------------
DROP TABLE IF EXISTS order_baskets;
CREATE TABLE order_baskets AS
WITH basket_items AS (
    SELECT order_id, product_id FROM order_products_prior
    UNION ALL
    SELECT order_id, product_id FROM order_products_train
),
items_with_category AS (
    SELECT bi.order_id,
           p.aisle_id,
           cm.category
    FROM basket_items bi
    JOIN products     p  ON p.product_id = bi.product_id
    JOIN category_map cm ON cm.aisle_id  = p.aisle_id
)
SELECT o.order_id,
       o.user_id,
       o.order_number,
       o.eval_set,
       o.days_since_prior_order,
       CASE
           WHEN o.days_since_prior_order IS NULL          THEN 'first'
           WHEN o.days_since_prior_order = 0              THEN 'same_day'
           WHEN o.days_since_prior_order BETWEEN 1 AND 3  THEN 'short'
           WHEN o.days_since_prior_order BETWEEN 4 AND 7  THEN 'middle'
           ELSE                                                'long'   -- 8-30 days (30 = "30 or more")
       END                                                       AS interval_group,
       COUNT(*)                                                  AS n_items,
       COUNT(DISTINCT i.aisle_id)                                AS n_aisles,
       SUM(CASE WHEN i.category = 'eggs'          THEN 1 ELSE 0 END) AS eggs_items,
       SUM(CASE WHEN i.category = 'milk'          THEN 1 ELSE 0 END) AS milk_items,
       SUM(CASE WHEN i.category = 'yogurt'        THEN 1 ELSE 0 END) AS yogurt_items,
       SUM(CASE WHEN i.category = 'poultry'       THEN 1 ELSE 0 END) AS poultry_items,
       SUM(CASE WHEN i.category = 'seafood'       THEN 1 ELSE 0 END) AS seafood_items,
       SUM(CASE WHEN i.category = 'fresh_produce' THEN 1 ELSE 0 END) AS fresh_produce_items,
       SUM(CASE WHEN i.category = 'snacks'        THEN 1 ELSE 0 END) AS snacks_items
FROM orders o
JOIN items_with_category i ON i.order_id = o.order_id
GROUP BY o.order_id, o.user_id, o.order_number, o.eval_set, o.days_since_prior_order;

CREATE INDEX idx_order_baskets_user ON order_baskets (user_id);
ANALYZE order_baskets;

-- -------------------------------------------------------------
-- 3. Checks
-- -------------------------------------------------------------
-- Expect 3,346,083 orders (all prior + train orders) and 33,819,106 items
SELECT COUNT(*) AS orders, SUM(n_items) AS items, COUNT(DISTINCT user_id) AS customers
FROM order_baskets;

-- Orders by interval group (used for the exclusions table)
SELECT interval_group,
       COUNT(*)                AS orders,
       COUNT(DISTINCT user_id) AS customers,
       ROUND(AVG(n_items), 2)  AS avg_items_pooled
FROM order_baskets
GROUP BY interval_group
ORDER BY MIN(COALESCE(days_since_prior_order, -1));

\copy (SELECT interval_group, COUNT(*) AS orders, COUNT(DISTINCT user_id) AS customers, ROUND(AVG(n_items), 2) AS avg_items_pooled FROM order_baskets GROUP BY interval_group ORDER BY MIN(COALESCE(days_since_prior_order, -1))) TO 'data/processed/orders_by_interval_group.csv' WITH (FORMAT csv, HEADER true)

-- Who places short-interval (1-3 day) orders?
--     Customers split into quarters by total number of orders.
--     (Explains why pooled comparisons mix up customer type and interval.)
WITH customer_orders AS (
    SELECT user_id, COUNT(*) AS n_orders
    FROM orders
    GROUP BY user_id
),
customer_quarters AS (
    SELECT user_id, NTILE(4) OVER (ORDER BY n_orders) AS activity_quarter
    FROM customer_orders
)
SELECT q.activity_quarter,
       ROUND(100.0 * SUM(CASE WHEN b.interval_group = 'short' THEN 1 ELSE 0 END)
             / SUM(SUM(CASE WHEN b.interval_group = 'short' THEN 1 ELSE 0 END)) OVER (), 1) AS pct_of_short_orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_all_orders
FROM order_baskets b
JOIN customer_quarters q ON q.user_id = b.user_id
GROUP BY q.activity_quarter
ORDER BY q.activity_quarter;
