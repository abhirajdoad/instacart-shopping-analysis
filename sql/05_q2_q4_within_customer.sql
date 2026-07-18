-- =============================================================
-- 05_q2_q4_within_customer.sql
-- Q2-Q4: compare the SAME customer's short- and long-interval orders.
--
--   short = 1-3 days since prior order
--   long  = 8-30 days since prior order (30 = "30 or more", kept in)
--
-- Excluded from the comparison: first orders (no interval), same-day
-- orders (0 days), the 4-7 day middle band, and 'test' orders
-- (no basket contents - already absent from order_baskets).
--
-- Qualifying customer: at least 1 short AND at least 1 long order.
-- Output: one row per qualifying customer per interval group, so each
-- customer can be given equal weight in the notebook.
-- =============================================================

DROP TABLE IF EXISTS within_customer;
CREATE TABLE within_customer AS
WITH comparison_orders AS (
    SELECT *
    FROM order_baskets
    WHERE interval_group IN ('short', 'long')
),
qualifying_customers AS (
    SELECT user_id
    FROM comparison_orders
    GROUP BY user_id
    HAVING SUM(CASE WHEN interval_group = 'short' THEN 1 ELSE 0 END) >= 1
       AND SUM(CASE WHEN interval_group = 'long'  THEN 1 ELSE 0 END) >= 1
)
SELECT c.user_id,
       c.interval_group,
       COUNT(*)                         AS n_orders,
       SUM(c.n_items)                   AS total_items,
       AVG(c.n_items)                   AS avg_basket_size,
       AVG(c.n_aisles)                  AS avg_distinct_aisles,
       -- Q3: share of this customer's items (in this interval group) per category, %
       100.0 * SUM(c.eggs_items)          / SUM(c.n_items) AS eggs_share,
       100.0 * SUM(c.milk_items)          / SUM(c.n_items) AS milk_share,
       100.0 * SUM(c.yogurt_items)        / SUM(c.n_items) AS yogurt_share,
       100.0 * SUM(c.poultry_items)       / SUM(c.n_items) AS poultry_share,
       100.0 * SUM(c.seafood_items)       / SUM(c.n_items) AS seafood_share,
       100.0 * SUM(c.fresh_produce_items) / SUM(c.n_items) AS fresh_produce_share,
       100.0 * SUM(c.snacks_items)        / SUM(c.n_items) AS snacks_share,
       -- Q4: % of this customer's orders (in this interval group) containing the category
       100.0 * AVG(CASE WHEN c.eggs_items          > 0 THEN 1 ELSE 0 END) AS eggs_presence,
       100.0 * AVG(CASE WHEN c.milk_items          > 0 THEN 1 ELSE 0 END) AS milk_presence,
       100.0 * AVG(CASE WHEN c.yogurt_items        > 0 THEN 1 ELSE 0 END) AS yogurt_presence,
       100.0 * AVG(CASE WHEN c.poultry_items       > 0 THEN 1 ELSE 0 END) AS poultry_presence,
       100.0 * AVG(CASE WHEN c.seafood_items       > 0 THEN 1 ELSE 0 END) AS seafood_presence,
       100.0 * AVG(CASE WHEN c.fresh_produce_items > 0 THEN 1 ELSE 0 END) AS fresh_produce_presence,
       100.0 * AVG(CASE WHEN c.snacks_items        > 0 THEN 1 ELSE 0 END) AS snacks_presence,
       -- sensitivity check: number of long orders that were capped at 30
       SUM(CASE WHEN c.days_since_prior_order = 30 THEN 1 ELSE 0 END) AS n_capped_orders
FROM comparison_orders c
JOIN qualifying_customers q ON q.user_id = c.user_id
GROUP BY c.user_id, c.interval_group;

-- Check: expect 88,202 customers, each with exactly 2 rows
SELECT COUNT(DISTINCT user_id) AS customers,
       COUNT(*)                AS rows,
       SUM(n_orders)           AS orders_analysed
FROM within_customer;

-- Quick customer-weighted summary
SELECT interval_group,
       COUNT(*)                          AS customers,
       ROUND(AVG(avg_basket_size), 2)    AS avg_basket_size,
       ROUND(AVG(avg_distinct_aisles), 2) AS avg_distinct_aisles
FROM within_customer
GROUP BY interval_group;

-- Export: one row per customer with short_ and long_ columns side by side.
-- No customer identifier; values rounded to 3 decimals; only columns the notebook uses.
\copy (SELECT s.n_orders AS short_n_orders, l.n_orders AS long_n_orders, ROUND(s.avg_basket_size::numeric, 3) AS short_avg_basket_size, ROUND(l.avg_basket_size::numeric, 3) AS long_avg_basket_size, ROUND(s.avg_distinct_aisles::numeric, 3) AS short_avg_distinct_aisles, ROUND(l.avg_distinct_aisles::numeric, 3) AS long_avg_distinct_aisles, ROUND(s.eggs_share::numeric, 3) AS short_eggs_share, ROUND(l.eggs_share::numeric, 3) AS long_eggs_share, ROUND(s.milk_share::numeric, 3) AS short_milk_share, ROUND(l.milk_share::numeric, 3) AS long_milk_share, ROUND(s.yogurt_share::numeric, 3) AS short_yogurt_share, ROUND(l.yogurt_share::numeric, 3) AS long_yogurt_share, ROUND(s.poultry_share::numeric, 3) AS short_poultry_share, ROUND(l.poultry_share::numeric, 3) AS long_poultry_share, ROUND(s.seafood_share::numeric, 3) AS short_seafood_share, ROUND(l.seafood_share::numeric, 3) AS long_seafood_share, ROUND(s.fresh_produce_share::numeric, 3) AS short_fresh_produce_share, ROUND(l.fresh_produce_share::numeric, 3) AS long_fresh_produce_share, ROUND(s.snacks_share::numeric, 3) AS short_snacks_share, ROUND(l.snacks_share::numeric, 3) AS long_snacks_share, ROUND(s.eggs_presence::numeric, 3) AS short_eggs_presence, ROUND(l.eggs_presence::numeric, 3) AS long_eggs_presence, ROUND(s.milk_presence::numeric, 3) AS short_milk_presence, ROUND(l.milk_presence::numeric, 3) AS long_milk_presence, ROUND(s.yogurt_presence::numeric, 3) AS short_yogurt_presence, ROUND(l.yogurt_presence::numeric, 3) AS long_yogurt_presence, ROUND(s.poultry_presence::numeric, 3) AS short_poultry_presence, ROUND(l.poultry_presence::numeric, 3) AS long_poultry_presence, ROUND(s.seafood_presence::numeric, 3) AS short_seafood_presence, ROUND(l.seafood_presence::numeric, 3) AS long_seafood_presence, ROUND(s.fresh_produce_presence::numeric, 3) AS short_fresh_produce_presence, ROUND(l.fresh_produce_presence::numeric, 3) AS long_fresh_produce_presence, ROUND(s.snacks_presence::numeric, 3) AS short_snacks_presence, ROUND(l.snacks_presence::numeric, 3) AS long_snacks_presence FROM within_customer s JOIN within_customer l ON l.user_id = s.user_id AND l.interval_group = 'long' WHERE s.interval_group = 'short' ORDER BY 1, 2, 3, 4, 5, 6) TO 'data/processed/within_customer.csv' WITH (FORMAT csv, HEADER true)

-- -------------------------------------------------------------
-- Q4 "bigger version of the usual cart?" check:
-- distinct aisles by basket size, for qualifying customers' orders.
-- If short and long baskets of the SAME size touch the same number of
-- aisles, extra aisles in long baskets come from size, not a new mix.
-- -------------------------------------------------------------
DROP TABLE IF EXISTS aisles_by_basket_size;
CREATE TABLE aisles_by_basket_size AS
SELECT b.interval_group,
       b.n_items,
       COUNT(*)                 AS orders,
       AVG(b.n_aisles)          AS avg_distinct_aisles
FROM order_baskets b
JOIN (SELECT DISTINCT user_id FROM within_customer) q ON q.user_id = b.user_id
WHERE b.interval_group IN ('short', 'long')
  AND b.n_items <= 30
GROUP BY b.interval_group, b.n_items;

\copy (SELECT interval_group, n_items, orders, ROUND(avg_distinct_aisles::numeric, 3) AS avg_distinct_aisles FROM aisles_by_basket_size ORDER BY interval_group, n_items) TO 'data/processed/aisles_by_basket_size.csv' WITH (FORMAT csv, HEADER true)

-- Size-matched within-customer check: orders with 5-10 items only.
DROP TABLE IF EXISTS within_customer_size_matched;
CREATE TABLE within_customer_size_matched AS
WITH sized AS (
    SELECT b.user_id, b.interval_group, b.n_aisles, b.n_items
    FROM order_baskets b
    JOIN (SELECT DISTINCT user_id FROM within_customer) q ON q.user_id = b.user_id
    WHERE b.interval_group IN ('short', 'long')
      AND b.n_items BETWEEN 5 AND 10
),
both_groups AS (
    SELECT user_id
    FROM sized
    GROUP BY user_id
    HAVING COUNT(DISTINCT interval_group) = 2
)
SELECT s.user_id,
       s.interval_group,
       COUNT(*)           AS n_orders,
       AVG(s.n_items)     AS avg_basket_size,
       AVG(s.n_aisles)    AS avg_distinct_aisles
FROM sized s
JOIN both_groups bg ON bg.user_id = s.user_id
GROUP BY s.user_id, s.interval_group;

-- Export: one row per customer, no identifier
\copy (SELECT ROUND(s.avg_basket_size::numeric, 3) AS short_avg_basket_size, ROUND(l.avg_basket_size::numeric, 3) AS long_avg_basket_size, ROUND(s.avg_distinct_aisles::numeric, 3) AS short_avg_distinct_aisles, ROUND(l.avg_distinct_aisles::numeric, 3) AS long_avg_distinct_aisles FROM within_customer_size_matched s JOIN within_customer_size_matched l ON l.user_id = s.user_id AND l.interval_group = 'long' WHERE s.interval_group = 'short' ORDER BY 1, 2, 3, 4) TO 'data/processed/within_customer_size_matched.csv' WITH (FORMAT csv, HEADER true)

-- -------------------------------------------------------------
-- Sensitivity checks (printed only; read into the notebook as CSV)
--  (a) Q2 with long = 8-29 days, i.e. dropping capped "30+" orders
--  (b) Average order_number of short vs long orders, to see whether
--      short-interval orders happen at a different stage of tenure
-- -------------------------------------------------------------
DROP TABLE IF EXISTS sensitivity_checks;
CREATE TABLE sensitivity_checks AS
WITH per_customer AS (
    SELECT b.user_id,
           AVG(CASE WHEN b.interval_group = 'short' THEN b.n_items END)               AS short_basket,
           AVG(CASE WHEN b.interval_group = 'long' THEN b.n_items END)                AS long_basket,
           AVG(CASE WHEN b.interval_group = 'long'
                     AND b.days_since_prior_order < 30 THEN b.n_items END)            AS long_basket_uncapped,
           AVG(CASE WHEN b.interval_group = 'short' THEN b.order_number END)          AS short_order_number,
           AVG(CASE WHEN b.interval_group = 'long' THEN b.order_number END)           AS long_order_number
    FROM order_baskets b
    JOIN (SELECT DISTINCT user_id FROM within_customer) q ON q.user_id = b.user_id
    WHERE b.interval_group IN ('short', 'long')
    GROUP BY b.user_id
)
SELECT 'Q2 main (long = 8-30 days)' AS check_name,
       COUNT(*) AS customers,
       ROUND(AVG(short_basket), 2) AS short_value,
       ROUND(AVG(long_basket), 2)  AS long_value,
       ROUND(AVG(long_basket - short_basket), 2) AS avg_difference
FROM per_customer
UNION ALL
SELECT 'Q2 excluding capped 30-day orders (long = 8-29 days)',
       COUNT(*),
       ROUND(AVG(short_basket), 2),
       ROUND(AVG(long_basket_uncapped), 2),
       ROUND(AVG(long_basket_uncapped - short_basket), 2)
FROM per_customer
WHERE long_basket_uncapped IS NOT NULL
UNION ALL
SELECT 'Average order number (tenure stage)',
       COUNT(*),
       ROUND(AVG(short_order_number), 2),
       ROUND(AVG(long_order_number), 2),
       ROUND(AVG(long_order_number - short_order_number), 2)
FROM per_customer;

SELECT * FROM sensitivity_checks;

\copy (SELECT * FROM sensitivity_checks) TO 'data/processed/sensitivity_checks.csv' WITH (FORMAT csv, HEADER true)
