-- =============================================================
-- 02_data_profiling.sql
-- Data-quality and structure checks run before the analysis.
-- Read-only: nothing is created or changed.
--   psql -d instacart -f sql/02_data_profiling.sql
-- =============================================================

-- 1. Row counts per table
SELECT 'aisles' AS table_name, COUNT(*) AS row_count FROM aisles
UNION ALL SELECT 'departments', COUNT(*) FROM departments
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_products_prior', COUNT(*) FROM order_products_prior
UNION ALL SELECT 'order_products_train', COUNT(*) FROM order_products_train;

-- 2. Orders and customers per eval_set.
--    'test' orders have NO basket contents in the public data.
SELECT eval_set,
       COUNT(*)                AS orders,
       COUNT(DISTINCT user_id) AS customers,
       SUM(CASE WHEN days_since_prior_order IS NULL THEN 1 ELSE 0 END) AS missing_interval
FROM orders
GROUP BY eval_set;

-- 3. Missing intervals should only occur on first orders
SELECT order_number = 1                 AS is_first_order,
       days_since_prior_order IS NULL   AS interval_missing,
       COUNT(*)                         AS orders
FROM orders
GROUP BY 1, 2;

-- 4. Orders per customer (Instacart supplied 4-100 orders per customer)
SELECT MIN(n_orders) AS min_orders,
       MAX(n_orders) AS max_orders,
       ROUND(AVG(n_orders), 2) AS avg_orders,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY n_orders) AS median_orders
FROM (SELECT user_id, COUNT(*) AS n_orders FROM orders GROUP BY user_id) AS per_customer;

-- 5. Distribution of days since prior order (note the spike at 30 = cap)
SELECT days_since_prior_order,
       COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM orders
GROUP BY days_since_prior_order
ORDER BY days_since_prior_order;

-- 6. Referential integrity: basket rows without a matching order / product
SELECT
    (SELECT COUNT(*) FROM order_products_prior op
       LEFT JOIN orders o ON o.order_id = op.order_id
      WHERE o.order_id IS NULL)              AS prior_rows_without_order,
    (SELECT COUNT(*) FROM order_products_prior op
       LEFT JOIN products p ON p.product_id = op.product_id
      WHERE p.product_id IS NULL)            AS prior_rows_without_product;

-- 7. Duplicate product lines within an order
SELECT COUNT(*) AS duplicated_order_product_pairs
FROM (SELECT order_id, product_id
      FROM order_products_prior
      GROUP BY order_id, product_id
      HAVING COUNT(*) > 1) AS dups;

-- 8. Prior orders with no basket rows
SELECT COUNT(*) AS prior_orders_without_items
FROM orders o
WHERE o.eval_set = 'prior'
  AND NOT EXISTS (SELECT 1 FROM order_products_prior op WHERE op.order_id = o.order_id);

-- 9. Each aisle belongs to exactly one department (needed for the snacks definition)
SELECT aisle_id, COUNT(DISTINCT department_id) AS departments
FROM products
GROUP BY aisle_id
HAVING COUNT(DISTINCT department_id) > 1;
