-- Version 1.1, Last Modified: 2025-02-06
-- This script is for data transformation and enrichment. Transform data into meaningful formats


/*
 * Objectives
 * [X -- line 23] 1. Create Total Revenue KPI to display the revenue Yearly and/or Monthly basis.
 * 1a. Total Revenue per product
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

