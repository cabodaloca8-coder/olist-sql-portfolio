-- Purpose: examine monthly trends in order counts and product value
-- Period: purchase months January 2017–August 2018
-- Scope: delivered orders with matching order-item records
-- Value basis: sum of item prices, excluding freight

-- order_month: purchase month
-- order_count: distinct order count
-- monthly_revenue: total monthly product value
-- avg_order_revenue: average product value per order

-- Aggregation note: the join returns one row per order item.
-- Use COUNT(DISTINCT o.order_id) to count orders.

-- Validation: order counts, totals, and averages for January and February 2017
-- match the CTE approach that aggregates item prices per order first.
-- Limitation: canceled and undelivered orders, and freight charges, are excluded.
SELECT SUBSTR(order_purchase_timestamp,1,7) AS order_month,
    COUNT(DISTINCT o.order_id) AS order_count,
      ROUND(SUM(price),2) AS monthly_revenue,
    ROUND(SUM(price)/COUNT(DISTINCT o.order_id),2) AS avg_order_revenue
    FROM orders o JOIN order_items oi ON o.order_id =oi.order_id
WHERE  order_status ='delivered' AND order_month >= '2017-01' AND order_month < '2018-09'
GROUP BY order_month
ORDER BY order_month ASC;

