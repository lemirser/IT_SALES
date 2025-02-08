-- Version 1.6, Last Modified: 2025-02-08
-- This script is for data transformation and enrichment. Transform data into meaningful formats


/*
 * Objectives
 * [X -- line 23] 1. Create Total Revenue KPI to display the revenue Yearly and/or Monthly basis.
 * [X -- line 56] 1a. Total Revenue per product
 * [X -- line 110] 2. Sales Growth Rate to check if the sales per Year or Month fluctuates
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
    ROUND(avg(od.subtotal),2) Average_sales
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
    ROUND(avg(od.subtotal),2) Average_sales
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


##### ##### #####
-- 2. Sales Growth Rate to check if the sales per Year or Month fluctuates

SELECT * FROM orders;

/*
 * The query displays the difference in sales between each month (current and the previous months).
 * This can tell us if there is growth in our sales each month.
 */
WITH monthly_sales AS (
SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS order_month,
        SUM(o.unit_price) AS total_sales
FROM
    orders o
WHERE
    o.status = 'Completed'
    AND o.has_order_details = 1
GROUP BY
    order_month
)
SELECT
    curr_orders.order_month AS curr_order_month,
    prev_orders.order_month AS prev_order_month,
    curr_orders.total_sales AS curr_sales,
    prev_orders.total_sales AS prev_sales,
    ROUND(((curr_orders.total_sales - prev_orders.total_sales) / prev_orders.total_sales) * 100, 2) AS sales_growth_percentage
FROM
    monthly_sales curr_orders
LEFT JOIN monthly_sales prev_orders
    ON
    prev_orders.order_month = DATE_FORMAT(STR_TO_DATE(DATE_SUB(CONCAT(curr_orders.order_month, '-01'), INTERVAL 1 MONTH), '%Y-%m-%d'), '%Y-%m')
ORDER BY
    curr_orders.order_month ASC;


/*
 * The query below shows us that there's a 45.8% in sales growth between the year of 2023 and 2024.
 */
WITH yearly_sales AS (
SELECT
        YEAR(order_date) AS order_year,
        SUM(o.unit_price) AS total_sales
FROM
    orders o
WHERE
    o.status = 'Completed'
    AND o.has_order_details = 1
GROUP BY
    order_year
)
SELECT
    curr_orders.order_year AS curr_order_year,
    prev_orders.order_year AS prev_order_year,
    curr_orders.total_sales AS curr_sales,
    prev_orders.total_sales AS prev_sales,
    ROUND(((curr_orders.total_sales - prev_orders.total_sales) / prev_orders.total_sales) * 100, 2) AS sales_growth_percentage
FROM
    yearly_sales curr_orders
LEFT JOIN yearly_sales prev_orders
    ON
    prev_orders.order_year = YEAR(STR_TO_DATE(DATE_SUB(CONCAT(curr_orders.order_year, '-01-01'), INTERVAL 1 Year), '%Y-%m-%d'))
ORDER BY
    curr_orders.order_year ASC;