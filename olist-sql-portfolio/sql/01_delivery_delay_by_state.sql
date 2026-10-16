-- Purpose: compare late delivery rates by customer state
-- Period: purchase timestamp >= 2017-01-01 and < 2018-09-01
-- Scope: delivered orders with both actual and estimated delivery dates
-- Late delivery: actual delivery date is after the estimated delivery date
-- Use DATE() to compare calendar dates without time components.

-- customer_state: state where the customer resides
-- order_count: number of eligible orders
-- late_order_count: number of late orders
-- late_rate_pct: late orders / eligible orders × 100

-- Display only states with at least 100 eligible orders.
-- Sort by late delivery rate descending, then order count descending.

-- Data validation:
-- customers.customer_id: 0 duplicate groups
-- 0 orders without a matching customer
-- 96,211 delivered orders within the purchase period
-- Exclude 8 orders with missing dates (approximately 0.0083%): 96,203 remain.
-- These counts are before applying the minimum of 100 orders per state.
-- AL-only check matches: 396 orders, 85 late orders, 21.46% late.

-- Limitation: order volumes and product/seller mixes differ across states.
-- Late delivery rates alone do not establish the causes of these differences.
-- Follow-up: examine monthly late delivery rates in AL to identify whether delays cluster in particular periods.
SELECT c.customer_state,
COUNT(*) AS order_count,
SUM(
CASE
    WHEN DATE (o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
THEN 1
ELSE 0
END
) AS late_order_count,
ROUND(
               100.0 *
               SUM(
                       CASE
                           WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
                               THEN 1
                           ELSE 0
                           END) / COUNT(*), 2
)AS late_rate_pct
    FROM customers c
Join orders o ON c.customer_id = o.customer_id
 WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
 AND o.order_estimated_delivery_date IS NOT NULL
 AND o.order_purchase_timestamp >= '2017-01-01' AND o.order_purchase_timestamp < '2018-09-01'
 GROUP BY c.customer_state  HAVING COUNT(*) >= 100 ORDER BY late_rate_pct DESC, order_count DESC;


-- Validation: filter AL separately and compare with the state-level result
-- Result matches: 396 orders, 85 late orders, 21.46% late.
-- Check scope: consistency of the AL filter and aggregation
SELECT
COUNT(*) AS order_count,
SUM(
CASE
    WHEN DATE (o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
THEN 1
ELSE 0
END
) AS late_order_count,
ROUND(
               100.0 *
               SUM(
                       CASE
                           WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
                               THEN 1
                           ELSE 0
                           END) / COUNT(*), 2
)AS late_rate_pct
    FROM customers c
Join orders o ON c.customer_id = o.customer_id
 WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
 AND o.order_estimated_delivery_date IS NOT NULL
 AND o.order_purchase_timestamp >= '2017-01-01' AND o.order_purchase_timestamp < '2018-09-01'
 AND c.customer_state = 'AL'
 ;

-- CTE version of the same analysis, for comparison with the main query
-- Comparison: both versions return 24 rows.
-- AL matches: 396 orders, 85 late orders, 21.46% late.
WITH delivered_orders AS (
    SELECT c.customer_state, COUNT(*) AS order_count,
           SUM(
CASE
    WHEN DATE (o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
THEN 1
ELSE 0
END
) AS late_order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND o.order_purchase_timestamp >= '2017-01-01'
AND o.order_purchase_timestamp < '2018-09-01'
  AND o.order_delivered_customer_date IS NOT NULL
 AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY c.customer_state
)
SELECT customer_state,
       order_count,
       late_order_count,
       ROUND(100.0 * late_order_count/order_count, 2)
       AS late_rate_pct

FROM delivered_orders WHERE order_count >= 100 ORDER BY late_rate_pct DESC, order_count DESC;
