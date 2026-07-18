-- =============================================================
-- 04_q1_frequency_vs_volume.sql
-- Q1: Do customers who shop more often buy more items overall?
--
-- Comparable observation period: each customer's first 90 days of
-- observed history (day 0 = first observed order, day 90 inclusive).
-- Day numbers are rebuilt by adding up days_since_prior_order.
--
-- Eligibility: the customer's history must extend PAST day 90
-- (their final order, of any eval_set, falls after day 90), so the
-- whole window is observed. All orders inside the window then have
-- known baskets (the unknown 'test' order is always the last one).
--
-- Cap: a recorded 30 means "30 or more days", so day numbers after a
-- capped gap are a lower bound. has_capped_gap flags customers whose
-- window timing is therefore uncertain. Main results use customers
-- WITHOUT a capped gap; all eligible customers are a sensitivity check.
-- =============================================================

DROP TABLE IF EXISTS q1_customer_window;
CREATE TABLE q1_customer_window AS
WITH timeline AS (
    SELECT user_id,
           order_id,
           days_since_prior_order,
           SUM(COALESCE(days_since_prior_order, 0))
               OVER (PARTITION BY user_id ORDER BY order_number) AS day_number
    FROM orders
),
eligible_customers AS (
    SELECT user_id
    FROM timeline
    GROUP BY user_id
    HAVING MAX(day_number) > 90
),
window_orders AS (
    SELECT t.*
    FROM timeline t
    JOIN eligible_customers e ON e.user_id = t.user_id
    WHERE t.day_number <= 90
)
SELECT w.user_id,
       COUNT(*)                     AS orders_in_window,
       SUM(b.n_items)               AS items_in_window,
       ROUND(AVG(b.n_items), 2)     AS avg_basket_size,
       MAX(CASE WHEN w.days_since_prior_order = 30 THEN 1 ELSE 0 END) AS has_capped_gap,
       CASE
           WHEN COUNT(*) <= 5  THEN '4-5 orders'
           WHEN COUNT(*) <= 8  THEN '6-8 orders'
           WHEN COUNT(*) <= 12 THEN '9-12 orders'
           ELSE                     '13+ orders'
       END                          AS frequency_segment
FROM window_orders w
JOIN order_baskets b ON b.order_id = w.order_id
GROUP BY w.user_id;

-- Check: every window order matched a known basket (expect 0)
WITH timeline AS (
    SELECT user_id, order_id, eval_set,
           SUM(COALESCE(days_since_prior_order, 0))
               OVER (PARTITION BY user_id ORDER BY order_number) AS day_number
    FROM orders
)
SELECT COUNT(*) AS window_orders_without_basket
FROM timeline t
JOIN q1_customer_window q ON q.user_id = t.user_id
WHERE t.day_number <= 90
  AND t.eval_set = 'test';

-- Segment summary (customer-weighted averages)
SELECT frequency_segment,
       CASE WHEN has_capped_gap = 0 THEN 'exact timing' ELSE 'has capped gap' END AS timing,
       COUNT(*)                          AS customers,
       ROUND(AVG(orders_in_window), 2)   AS avg_orders,
       ROUND(AVG(avg_basket_size), 2)    AS avg_basket_size,
       ROUND(AVG(items_in_window), 1)    AS avg_items_90d
FROM q1_customer_window
GROUP BY frequency_segment, has_capped_gap
ORDER BY MIN(orders_in_window), has_capped_gap;

-- Export: one row per customer, NO customer identifier (only the columns the notebook needs)
\copy (SELECT frequency_segment, has_capped_gap, orders_in_window, items_in_window, avg_basket_size FROM q1_customer_window ORDER BY frequency_segment, has_capped_gap, orders_in_window, items_in_window, avg_basket_size) TO 'data/processed/q1_customer_window.csv' WITH (FORMAT csv, HEADER true)
