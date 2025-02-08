-- Version 1.4, Last Modified: 2025-02-08
-- This script is for data transformation and enrichment. Transform data into meaningful formats


/*
 * Objectives
 * [X -- line 23] 1. Create Total Revenue KPI to display the revenue Yearly and/or Monthly basis.
 * [X -- line 56] 1a. Total Revenue per product
 * 2. Sales Growth Rate to check if the sales per Year or Month fluctuates
 * 3. Average Revenue Per User to help measure customer value and pricing effectiveness
 * 4. Products Sales to see which products have the hightest sales record.
 * 5. Gross profit margin
 * 6. Net Profit margin
 * 7. Net profit vs net revenue vs net cost
 * 8. Most Payment method used/ Customer with most orders
 * 9. Delivered, Canceled, and pending orders comparison
 * 10. Customer retention rate
 */


USE it_sales;


##### ##### #####
-- 1. Create Total Revenue KPI to display the revenue Yearly and/or Monthly basis.
-- Yearly
-- Based on the result our highest sales is in 2024 so far with the total of 182 completed orders for that year.
SELECT
    DISTINCT YEAR(order_date) `Year`,
    SUM(unit_price) Revenue,
    count(DISTINCT order_id) AS Completed_order
FROM
    orders
WHERE
    status = 'completed'
GROUP BY 1
ORDER BY
    YEAR(order_date) ASC;

-- Monthly
-- Based on the report below, the 2024-12 has the highest sales and orders.
SELECT
    DISTINCT LEFT(order_date,7) `YYYY-MM`,
    SUM(unit_price) Revenue,
    count(DISTINCT order_id) order_count
FROM
    orders
WHERE
    status = 'completed'
GROUP BY
    1
ORDER BY
    LEFT(order_date,7) ASC;


##### ##### #####
-- 1a. Total Revenue per product
-- 220 out of 1000 orders does have order details
-- We will exclude orders without order details since can't generate the revenue per product
SELECT
    count(order_id)
FROM
    orders o
WHERE
    o.has_order_details = 1
AND o.status = 'Completed';

/*
 * Based on the result of the query, the Monitor sales have the highest sales every year.
 */
-- Yearly
SELECT
    DISTINCT YEAR(o.order_date) `Year`,
    p.product_type,
    count(product_type) Product_sales,
    SUM(od.subtotal) Total_sales,
    TRUNCATE(avg(od.subtotal),2) Average_sales
FROM
    orders o
INNER JOIN order_details od
ON o.order_id = od.order_id
LEFT JOIN products p
ON od.product_id = p.product_id
WHERE
    o.has_order_details = 1
    AND o.status = 'Completed'
GROUP BY 1,2
ORDER BY 1;

-- Monthly
SELECT
    DISTINCT LEFT(o.order_date,7) `YYYY-MM`,
    p.product_type,
    count(product_type) Product_sales,
    SUM(od.subtotal) Total_sales,
    TRUNCATE(avg(od.subtotal),2) Average_sales
FROM
    orders o
INNER JOIN order_details od
ON o.order_id = od.order_id
LEFT JOIN products p
ON od.product_id = p.product_id
WHERE
    o.has_order_details = 1
    AND o.status = 'Completed'
GROUP BY 1,2
ORDER BY 1;