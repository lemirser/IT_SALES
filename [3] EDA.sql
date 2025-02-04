-- Version 1.02, Last Modified: 2025-02-05
-- This script is Exploratory Data Analysis (EDA).


/*
 * Objectives:
 * [X -- line 11] 1. Data type validation
 * [X -- line 59] 2. Data overview
 * [X -- line 100] 3. Check for duplicates
 * 4. Standardize data
 * 5. Check for NULL values
 */

USE it_sales;
##### ##### #####
-- 1. Data type validation
-- Ensuring the data types for each tables are correct

/*
 * Common issues encountered:
 * Numbers stored as text
 * Dates stored as text
 */

-- For the phone_num column, if the business need to format the value, we can split the values by area code, main number and the extensions.
SELECT
    column_name,
    data_type
FROM
    information_schema.`COLUMNS` c
WHERE
    table_name = 'customer';

SELECT
    column_name,
    data_type
FROM
    information_schema.`COLUMNS` c
WHERE
    table_name = 'order_details';

SELECT
    column_name,
    data_type
FROM
    information_schema.`COLUMNS` c
WHERE
    table_name = 'orders';

SELECT
    column_name,
    data_type
FROM
    information_schema.`COLUMNS` c
WHERE
    table_name = 'products';


##### ##### #####
-- 2. Data overview
-- Checking of data summary. This can help in familiarizing the data and provide more insights with each tables.

-- List down the main tables
-- We have 'bak' (backup) tables since we proceed with data cleaning before EDA.
SHOW TABLES
WHERE
`Tables_in_it_sales` NOT LIKE '%bak%';


-- As we look into the phone_num data values, we can see that the data is not formatted/standardize. Since the customer phone numbers doesn't affect our analysis, we will not update the values unless the it is included in the business need.
SELECT
    *
FROM
    customer
LIMIT 10;


-- Order_id and product_id are foreign keys from orders and products tables respectively.
SELECT
    *
FROM
    order_details
LIMIT 10;


-- Based on the has_order_details column, we have orders that doesn't have any order detail/s.
SELECT
    *
FROM
    orders
LIMIT 10;

SELECT
    *
FROM
    products
LIMIT 10;


##### ##### #####
-- 3. Check for duplicates

--
/*
 * The query will add row numbers as new column, if the there are any duplicate/s, the value will be >1.
 * We limit the result since we only need to fetch values that are greater than 1.
 * If there are specific rules for each tables, we can use it in the 'partition by'.
 * For example, if there is a data validation in the customers table by only registering/using unique email address. We can don't have to include all the columns in the partition by since we only need to check for duplicate email address.
 *
 */
SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY customer_id,
    customer_name,
    email,
    phone_num,
    city,
    state,
    country,
    registration_date) AS dup_checker
FROM
    customer c
ORDER BY
    dup_checker DESC
LIMIT 10;


SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY order_id,
product_id,
quantity,
unit_price,
subtotal) AS dup_checker
FROM
    order_details
ORDER BY
    dup_checker DESC
LIMIT 10;

SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY order_id,
customer_id,
order_date,
unit_price,
payment_method,
status,
has_order_details) AS dup_checker
FROM
    orders
ORDER BY
    dup_checker DESC
LIMIT 10;

SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY order_id,
customer_id,
order_date,
unit_price,
payment_method,
status,
has_order_details) AS dup_checker
FROM
    orders
ORDER BY
    dup_checker DESC
LIMIT 10;

SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY product_id,
product_name,
category,
brand,
unit_price,
unit_cost,
stock_quantity) AS dup_checker
FROM
    products
ORDER BY
    dup_checker DESC
LIMIT 10;