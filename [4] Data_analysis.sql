-- Version 1.15, Last Modified: 2025-02-10
-- This script is for data transformation and enrichment. Transform data into meaningful formats


/*
 * Objectives
 * [X -- line 23] 1. Create Total Revenue KPI to display the revenue Yearly and/or Monthly basis.
 * [X -- line 56] 1a. Total Revenue per product
 * [X -- line 110] 2. Sales Growth Rate to check if the sales per Year or Month fluctuates
 * [X -- line 176] 3. Average Revenue Per User to help measure customer value and pricing effectiveness
 * [X -- line 254] 4. Products Sales to see which products have the hightest sales record.
 * [X -- line 291] 5. Gross profit margin
 * [X -- line 341] 6. Most Payment method used/ Customer with most orders
 * [X -- line 367] 7. Delivered, Canceled, and pending orders comparison
 * [X -- line 393]  8. Customer retention rate
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


##### ##### #####
-- 3. Average Revenue Per User to help measure customer value and pricing effectiveness
/*
 * With avpu, we can check which product yield a higher revenue sales per month/year.
 * We can also decide to run a discount sale or marketing ad during the month with the highest avg sale per product
 */
SELECT * FROM orders;

WITH avg_rpu_yearly AS (
SELECT
    YEAR(order_date) `Year`,
    sum(unit_price) Total_revenue,
    count(DISTINCT customer_id) Number_of_customers
FROM
    orders
WHERE
    has_order_details = 1
    AND status = 'Completed'
GROUP BY
    1)
SELECT
    `Year`,
    Total_revenue,
    ROUND(Total_revenue/Number_of_customers ,2) ARPU
FROM
    avg_rpu_yearly;

WITH avg_rpu_monthly AS (
SELECT
    DATE_FORMAT(order_date,'%Y-%m') `YYYY-MM`,
    sum(unit_price) Total_revenue,
    count(DISTINCT customer_id) Number_of_customers
FROM
    orders
WHERE
    has_order_details = 1
    AND status = 'Completed'
GROUP BY
    1)
SELECT
    `YYYY-MM`,
    Total_revenue,
    ROUND(Total_revenue/Number_of_customers ,2) ARPU
FROM
    avg_rpu_monthly
ORDER BY 1;

WITH avg_pu AS (
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') `YYYY-MM`,
    SUM(od.subtotal) AS product_sales,
    -- p.product_brand,
    p.product_type,
    count(DISTINCT od.product_id) product_sold
FROM
    orders o
INNER JOIN order_details od ON
    o.order_id = od.order_id
LEFT JOIN products p ON
    p.product_id = od.product_id
WHERE
    o.status = 'Completed'
    AND o.has_order_details = 1
GROUP BY
    DATE_FORMAT(o.order_date, '%Y-%m'),
    -- p.product_brand,
    p.product_type)
SELECT
    `YYYY-MM`,
    -- product_brand,
    product_type,
    product_sold,
    product_sales,
    ROUND(product_sales/product_sold, 2) AS avg_revenue_per_unit
FROM
    avg_pu;


##### ##### #####
-- 4. Products Sales to see which products have the hightest sales record.
use it_sales;

SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') `YYYY-MM`,
    p.product_type,
    sum(od.subtotal) product_sales
FROM
    orders o
LEFT JOIN order_details od ON
    o.order_id = od.order_id
LEFT JOIN products p ON
    od.product_id = p.product_id
WHERE
    o.has_order_details = 1
    AND o.status = 'Completed'
GROUP BY 1,2
ORDER BY 1 ASC;

SELECT
    DATE_FORMAT(o.order_date, '%Y') `Year`,
    p.product_type,
    sum(od.subtotal) product_sales
FROM
    orders o
LEFT JOIN order_details od ON
    o.order_id = od.order_id
LEFT JOIN products p ON
    od.product_id = p.product_id
WHERE
    o.has_order_details = 1
    AND o.status = 'Completed'
GROUP BY 1,2
ORDER BY 1 ASC;


##### ##### #####
-- 5. Gross profit margin
/*
 * By generating the gross profit margin, we can understand the profitability of specific items rather.
 * Calculating gross margin can show if the business is spending too much on a product.
 */

SELECT
    YEAR(o.order_date) `Year`,
    p.product_type,
    sum(od.subtotal) product_sales,
    sum(p.unit_cost) product_cost,
    sum(od.quantity),
    ROUND(((sum(od.subtotal)-sum(p.unit_cost))/sum(od.subtotal))*100,2) gross_profit_margin_percentage
FROM
    orders o
LEFT JOIN order_details od ON
    o.order_id = od.order_id
LEFT JOIN products p ON
    p.product_id = od.product_id
WHERE
    o.status = 'Completed'
    AND o.has_order_details = 1
GROUP BY
    1,
    2
ORDER BY
    1,2 ASC;

SELECT
    DATE_FORMAT(o.order_date,'%Y-%m') `YYYY-MM`,
    p.product_type,
    sum(od.subtotal) product_sales,
    sum(p.unit_cost) product_cost,
    sum(od.quantity),
    ROUND(((sum(od.subtotal)-sum(p.unit_cost))/sum(od.subtotal))*100,2) gross_profit_margin_percentage
FROM
    orders o
LEFT JOIN order_details od ON
    o.order_id = od.order_id
LEFT JOIN products p ON
    p.product_id = od.product_id
WHERE
    o.status = 'Completed'
    AND o.has_order_details = 1
GROUP BY
    1,
    2
ORDER BY
    1 ASC;


##### ##### #####
-- 6. Most Payment method used
SELECT
    YEAR(order_date) `Year`,
    payment_method,
    COUNT(payment_method) payment_method_used
FROM
    orders
GROUP BY
    1,
    2
ORDER BY
    1 ASC;

SELECT
    DATE_FORMAT(order_date, '%Y-%m') `YYYY-MM`,
    payment_method,
    COUNT(payment_method) payment_method_used
FROM
    orders
GROUP BY
    1,
    2
ORDER BY 1 ASC;


##### ##### #####
-- 7. Delivered, Canceled, and pending orders comparison

/*
 * By displaying the breakdown between Completed, Canceled, and Pending orders, we can investigate if there are more Canceled orders than Completed orders each month/ year. We can then check further what might be causing the issue.
 */

SELECT
    YEAR(order_date) `Year`,
    status,
    COUNT(status) order_status
FROM
    orders
GROUP BY 1,2
ORDER BY 1, 2;

SELECT
    DATE_FORMAT(order_date,'%Y-%m') `YYYY-MM`,
    status,
    COUNT(status) order_status
FROM
    orders
GROUP BY 1,2
ORDER BY 1, 2;


##### ##### #####
-- 8. Customer retention rate


WITH previous_year AS (
-- Select customers who ordered previous year
SELECT
    DISTINCT customer_id,
    YEAR(order_date) AS YEAR
FROM
    orders
WHERE
    has_order_details = 1
    AND status = 'Completed'),
current_year AS (
-- Query for current year
SELECT
    DISTINCT customer_id,
    YEAR(order_date) AS YEAR
FROM
    orders
WHERE
    has_order_details = 1
    AND status = 'Completed'
),
retained_customers AS (
-- Count customers who ordered in consecutive year
SELECT
    py.YEAR previous_year,
    COALESCE(cy.YEAR,NULL) current_year,
    count(DISTINCT py.customer_id) retained_customers
FROM
    previous_year py
LEFT JOIN current_year cy
ON
    py.customer_id = cy.customer_id
    AND cy.`year` = py.`year` + 1
GROUP BY
    1,
    2),
total_previous AS (
-- Counts total unique customers in each previous year
SELECT
    `year` AS previous_year,
    COUNT(DISTINCT customer_id) AS total_customers
FROM
    previous_year
GROUP BY
    `year`
    )
SELECT
    r.previous_year,
    r.current_year,
    r.retained_customers,
    t.total_customers AS previous_year_customers,
    (r.retained_customers * 100.0 / t.total_customers) AS retention_rate
FROM
    retained_customers r
JOIN total_previous t
ON
    r.previous_year = t.previous_year
ORDER BY
    r.previous_year;


##### ##### #####
WITH rfm AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_purchase, -- Recency
        COUNT(order_id) AS frequency,    -- Frequency
        SUM(unit_price) AS monetary     -- Monetary
    FROM orders
    WHERE status = 'Completed'
    GROUP BY customer_id
)
SELECT
    customer_id,
    DATEDIFF(CURRENT_DATE(), last_purchase) AS recency, -- Count the days the customer LAST ordered
    frequency,
    monetary
FROM rfm
ORDER BY recency ASC, monetary DESC;

/*
 * Example of customer types with rfm scores:
 *
 * Whales: The biggest customers with high (5,5,5) values in all three factors that should be targeted with special promotions to keep them active.
 * New Customers: Customers with high recency and low frequency (5,1,X) are new customers. A targeted follow-up may convert them into repeat customers.
 * Lapsed customers: Customers with low recency but high value (1,X,5) were once valuable customers but have since stopped. Atargeted message may reactivate them.
 *
 * Source: https://www.techtarget.com/searchdatamanagement/definition/RFM-analysis#:~:text=Some%20examples%20of,may%20reactivate%20them.
 */
WITH rfm AS (
    SELECT
        customer_id,
        status AS order_status,
        MAX(order_date) AS last_purchase, -- Recency
        COUNT(order_id) AS frequency,    -- Frequency
        SUM(unit_price) AS monetary     -- Monetary
    FROM orders
    WHERE status IN ('Completed','Pending')
    GROUP BY customer_id, status
),rfm_scores AS (
    SELECT
        customer_id,
        -- Divide the data into 5 groups, which in turn acts as a rating/counting system 1-5 for recency_score, frequency_score, and monetary_score
        NTILE(5) OVER (ORDER BY DATEDIFF(CURRENT_DATE(), last_purchase) DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score
    FROM rfm
)
SELECT
    customer_id,
    recency_score,
    frequency_score,
    monetary_score,
    (recency_score + frequency_score + monetary_score) AS rfm_total
FROM rfm_scores
ORDER BY rfm_total DESC;