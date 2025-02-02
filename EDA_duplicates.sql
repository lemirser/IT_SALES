-- Version 1.0, Last Modified: 2025-02-03
-- This script is for expliritory data analysis to check for duplicates.

/*
 * Exploritory data analysis
 * 1. Remove duplicates
 * 2. Standardize data
 * 3. NULL values
 * 4. Remove any columns we don't need
 */

-- Checking for duplicates
-- Customer table
USE it_sales;


/*
 * Checks for any duplicate data for the customers table.
 * By using ROW_NUMBER() OVER (), it will create row numbers per row and will group the data if encountered any duplicate based on the OVER ()
 */
WITH duplicate_customers AS (
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY customer_id,
    customer_name,
    email,
    phone_num,
    city,
    state,
    country,
    registration_date) AS row_num
FROM
    customer)
SELECT
    *
FROM
    duplicate_customers
WHERE
    row_num > 1;


/*
 * Checks for any duplicate data for the orders table.
 */
SELECT
    order_id,
    COUNT(DISTINCT order_id)
FROM
    orders
GROUP BY
    1
HAVING
    COUNT(DISTINCT order_id) > 1;

/*
 * Checks for any duplicate data for the products table.
 * By using ROW_NUMBER() OVER (), it will create row numbers per row and will group the data if encountered any duplicate based on the OVER ()
 */
WITH duplicate_products AS (
SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY product_id,
    product_name,
    category,
    brand,
    price,
    stock_quantity) AS row_num
FROM
    products p)
SELECT
    *
FROM
    duplicate_products
WHERE
    row_num > 1;


/*
 * There is no need to check for duplicate entries in order_details table.
 */
SELECT
    *
    FROM order_details od
LIMIT 10;