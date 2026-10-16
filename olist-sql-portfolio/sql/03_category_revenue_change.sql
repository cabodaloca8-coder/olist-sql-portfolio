-- Analysis: change in product value from October to November 2017
-- Scope: delivered orders; freight excluded
-- Total net increase: 339,517.72
-- bed_bath_table increase: 41,949.93
-- Share of the total net increase: 12.36%
-- Validation: sum of category changes matches the difference in monthly totals.
-- Limitation: this analysis alone cannot establish the causes of growth.
WITH category_monthy_revenue AS (
      SELECT
      COALESCE(ct.product_category_name_english, 'unknown')
    AS product_category_name,
    SUM(CASE
        WHEN  SUBSTR(order_purchase_timestamp,1,7)='2017-10' THEN oi.price
    ELSE 0 END) AS october_revenue,
    SUM(CASE
    WHEN SUBSTR(order_purchase_timestamp,1,7) = '2017-11'THEN oi.price
    ELSE 0 END) AS november_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
 LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
WHERE (SUBSTR (order_purchase_timestamp,1,7) = '2017-10'
  OR SUBSTR (order_purchase_timestamp,1,7) = '2017-11')
  AND order_status = 'delivered'
GROUP BY COALESCE(ct.product_category_name_english, 'unknown'))
SELECT product_category_name, october_revenue, november_revenue,
      ROUND((november_revenue - october_revenue),2) AS revenue_change
    FROM category_monthy_revenue
    ORDER BY revenue_change DESC;
-- watches_gifts has the highest November product value; bed_bath_table has the largest increase from October.

WITH category_monthly_revenue AS (
      SELECT
   COALESCE(ct.product_category_name_english, 'unknown')
    AS product_category_name,
    SUM(CASE
        WHEN  SUBSTR(order_purchase_timestamp,1,7)='2017-10' THEN oi.price
    ELSE 0 END) AS october_revenue,
    SUM(CASE
    WHEN SUBSTR(order_purchase_timestamp,1,7) = '2017-11'THEN oi.price
    ELSE 0 END) AS november_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
 LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
WHERE (SUBSTR (order_purchase_timestamp,1,7) = '2017-10'
  OR SUBSTR (order_purchase_timestamp,1,7) = '2017-11')
  AND order_status = 'delivered'
GROUP BY COALESCE(ct.product_category_name_english, 'unknown'))
SELECT
      ROUND(SUM((november_revenue - october_revenue)),2) AS revenue_change
    FROM category_monthly_revenue;

-- bed_bath_table share of the total net increase
SELECT ROUND(100.0 * 41949.93 / 339517.72, 2);
