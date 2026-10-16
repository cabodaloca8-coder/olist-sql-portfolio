SELECT
    order_id,
    COUNT(*) AS duplicate_count
     FROM orders
     GROUP BY order_id HAVING COUNT(*) >1;

SELECT COUNT(*) AS missing_customer_id
FROM orders
WHERE customer_id IS NULL;

SELECT COUNT(*) AS missing_purchase_timestamp
FROM orders
WHERE order_purchase_timestamp IS NULL
OR order_purchase_timestamp = '';

SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

SELECT COUNT(*) AS missed_delivery
    FROM orders
        WHERE order_status = 'delivered' AND
              order_delivered_customer_date IS NULL;

-- Inspection queries

PRAGMA table_info(orders);

SELECT
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders
LIMIT 10;

-- Investigate missing English categories: October–November 2017
SELECT p.product_category_name AS product_category_name,
       COUNT(*) AS number_product,
       SUM(price) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
 LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
WHERE (SUBSTR (order_purchase_timestamp,1,7) = '2017-10' OR SUBSTR (order_purchase_timestamp,1,7) = '2017-11')
AND order_status = 'delivered'
AND ct.product_category_name_english IS NULL
AND p.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY revenue DESC;
-- Delivered orders in October–November 2017:
-- 186 order-item rows without an English category; total product value: 30,107.82
-- The original product_category_name is also NULL for these rows.
-- Retain these rows in the analysis under unknown.

-- Duplicate check: category_translation.product_category_name — 0 duplicate groups
SELECT COUNT(*) AS calc , product_category_name
FROM category_translation
GROUP BY product_category_name
HAVING calc >= 2;
-- Duplicate check: products.product_id — 0 duplicate groups
SELECT COUNT(*) AS calc , product_id
FROM products
GROUP BY product_id
HAVING calc >= 2;

-- order_items → products: 0 unmatched order-item rows
SELECT COUNT(*)
    FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Purchase timestamp range: August 2018
SELECT MIN(order_purchase_timestamp) AS earliest_purchase_date,
MAX(order_purchase_timestamp) AS latest_purchase_date
FROM orders
WHERE SUBSTR(order_purchase_timestamp,1,7) = '2018-08';

-- Order counts by purchase month and order status
SELECT SUBSTR(order_purchase_timestamp,1,7) AS month,
       order_status,
       COUNT(DISTINCT (order_id)) AS number_of_order
FROM  orders
GROUP BY month, order_status
ORDER BY month ASC, order_status ASC;


-- Duplicate check: customers.customer_id
SELECT customer_id, COUNT(*) AS calc
FROM customers
group by customer_id HAVING calc >= 2;

-- orders → customers: 0 unmatched orders
SELECT COUNT(*)
    FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;


-- Delivered orders purchased from January 2017 through August 2018:
-- 8 orders have a NULL actual or estimated delivery date.
-- Exclude these orders from the late delivery rate calculation.
SELECT COUNT(*) AS calc
FROM orders
WHERE order_status = 'delivered' AND order_purchase_timestamp >= '2017-01-01'
AND order_purchase_timestamp < '2018-09-01'
AND (order_delivered_customer_date IS NULL OR order_estimated_delivery_date IS NULL);


-- Missing delivery dates: 8 / 96,211 orders ≈ 0.0083%
-- 96,203 orders remain after excluding missing dates.
-- Apply the minimum of 100 eligible orders per state afterward.
SELECT COUNT(*) AS calc
FROM orders
WHERE order_status = 'delivered' AND order_purchase_timestamp >= '2017-01-01'
AND order_purchase_timestamp < '2018-09-01';

SELECT ROUND((8*100.0/96211),4) AS missing_date_pct;
