-- Version 1.09, Last Modified: 2025-02-07
-- This script is Exploratory Data Analysis (EDA).


/*
 * Objectives:
 * [X -- line 11] 1. Data type validation
 * [X -- line 59] 2. Data overview
 * [X -- line 100] 3. Check for duplicates
 * [X -- line 184] 4. Standardize data
 * [X -- line 299] 5. Separate product name (Brand, product_type, model number)
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

/*
 * The query will add row numbers as new column, if the there are any duplicate/s, the value will be >1.
 * We limit the result since we only need to fetch values that are greater than 1.
 * If there are specific rules for each tables, we can use it in the 'partition by'.
 * For example, if there is a data validation in the customers table by only registering/using unique email address. We can don't have to include all the columns in the partition by since we only need to check for duplicate email address.
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


##### ##### #####
-- 4. Standardize data
/*
 * REGEXP pattern use for `REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';`
 * ^        = Start of the string (ensures the match starts from the first character)
 * [0-9]{4} = Matches exactly four digits (representing the year)
 * -        = Matches a literal hyphen/dash as date separator
 * [0-9]{2} = Matches exactly two digits (representing the month or day)
 * -        = Matches a literal hyphen/dash as date separator
 * [0-9]{2} = Matches exactly two digits (representing the month or day)
 * $        = End of the string (ensures nothing follows the month or day)
 */
# Checking any inconsistency with the date format. We can use the YYYY-MM-DD format for all the tables.
SELECT
    *
FROM
    customer
WHERE
    registration_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';
-- RETURNS ALL the DATA that doesn't MATCH WITH the REGEXP (YYYY-MM-DD).

/*
 * Some customers have honorifics (Mr.,Ms.,Mrs.,Dr.) and degree (MD, DDS, DVM).
 * Since doesn't impact our reporting, we don't need to update the customer names.
 * But if there's a business requirement to format them, refer to the queries below.
 */

/*
 * REGEXP breakdown
 * '^(Dr\\.|Mrs\\.|Ms\\.|Mr\\.)'
 * ^                            = Start of the string
 * (Dr\\.|Mrs\\.|Ms\\.|Mr\\.)   = Search for Dr., Mrs., Ms., and Mr.. The \\. is to character escape the dot.
 * | (pipe)                     = It means OR condition
 * We can omit the ^, it will return as True even if the search instance is in the middle (ie. John Dr. Doe)
 */
SELECT
    c.customer_id,
    c.customer_name,
    CASE
        WHEN RIGHT(SUBSTRING_INDEX(c.customer_name, ' ', 1),
        1) <> '.' THEN NULL
        ELSE SUBSTRING_INDEX(c.customer_name, ' ', 1)
    END AS honorifics,
    CASE
        WHEN SUBSTRING_INDEX(c.customer_name, ' ', -1) NOT IN ('MD', 'DDS', 'DVM') THEN NULL
        ELSE SUBSTRING_INDEX(c.customer_name, ' ', -1)
    END AS prof_degree
FROM
    customer c
WHERE
    customer_name REGEXP '^(Dr\\.|Mrs\\.|Ms\\.|Mr\\.)'
    OR customer_name REGEXP '\\s(MD|DDS|DVM)$';

# DML logic testing
DROP TEMPORARY TABLE IF EXISTS customer_temp;

CREATE TEMPORARY TABLE customer_temp AS

/*
 * REGEXP breakdown
 * \\s = Matches any whitespace character (spaces, tabs, newlines)
 * * = Quantifier, matches zero or more occurrences of the preceding character/class (\s in our example)
 *
 * \\s = "Dr.John" <--- "Dr." will not be remove since \\s means there should be a whitespace between the identifier and the next string
 * \\s* = "Dr.John" <--- "Dr." will be removed since \\s* means whitespace with "zero or more times".
 */
UPDATE
    customer_temp c
SET
    customer_name = REGEXP_REPLACE(
        REGEXP_REPLACE(customer_name, '^(Dr\\.|Mrs\\.|Ms\\.|Mr\\.)\\s*', ''), -- Remove prefix
        '\\s*(MD|DDS|DVM)\\s*$', '' -- Remove suffix only if at the end
    )
WHERE
    customer_name REGEXP '^(Dr\\.|Mrs\\.|Ms\\.|Mr\\.)'
    OR customer_name REGEXP '\\s(MD|DDS|DVM)$';

-- Apply the DML to actual table
CREATE TABLE it_sales.customer_bak_2025_02_05 AS
SELECT
    *
FROM
    it_sales.customer;

UPDATE
    customer c
SET
    customer_name = REGEXP_REPLACE(
        REGEXP_REPLACE(customer_name, '^(Dr\\.|Mrs\\.|Ms\\.|Mr\\.)\\s*', ''), -- Remove prefix
        '\\s*(MD|DDS|DVM)\\s*$', '' -- Remove suffix only if at the end
    )
WHERE
    customer_name REGEXP '^(Dr\\.|Mrs\\.|Ms\\.|Mr\\.)'
    OR customer_name REGEXP '\\s(MD|DDS|DVM)$';

-- Verify the update. There should be zero result.
SELECT
    c.customer_id,
    c.customer_name,
    CASE
        WHEN RIGHT(SUBSTRING_INDEX(c.customer_name, ' ', 1),
        1) <> '.' THEN NULL
        ELSE SUBSTRING_INDEX(c.customer_name, ' ', 1)
    END AS honorifics,
    CASE
        WHEN SUBSTRING_INDEX(c.customer_name, ' ', -1) NOT IN ('MD', 'DDS', 'DVM') THEN NULL
        ELSE SUBSTRING_INDEX(c.customer_name, ' ', -1)
    END AS prof_degree
FROM
    customer c
WHERE
    customer_name REGEXP '^(Dr\\.|Mrs\\.|Ms\\.|Mr\\.)'
    OR customer_name REGEXP '\\s(MD|DDS|DVM)$';


##### ##### #####
-- 5. Separate product name (Brand, product_type, model number)
SELECT * FROM products p;

-- Fetch unique brand names
SELECT
    DISTINCT CASE
        WHEN product_name LIKE 'Western %' THEN "Western Digital"
        ELSE substring_index(p.product_name, ' ', 1)
    END product_brand
FROM
    products p;

-- Find product_model
SELECT
    product_name,
    SUBSTRING_INDEX(p.product_name,' ',-1) AS product_model
FROM
    products p;

-- Find product_type
SELECT
    product_name,
    CASE
        WHEN product_name LIKE 'Western %' THEN 'Storage'
        ELSE SUBSTRING_INDEX(SUBSTRING_INDEX(product_name, ' ', 2), ' ',-1)
    END product_type
FROM
    products;

-- Consolidated query
SELECT
    product_name,
    CASE
        WHEN product_name LIKE 'Western %' THEN "Western Digital"
        ELSE substring_index(p.product_name, ' ', 1)
    END product_brand,
    CASE
        WHEN product_name LIKE 'Western %' THEN 'Storage'
        ELSE SUBSTRING_INDEX(SUBSTRING_INDEX(product_name, ' ', 2), ' ',-1)
    END product_type,
    SUBSTRING_INDEX(p.product_name,' ',-1) AS product_model
FROM
    products p;

-- Backup table
CREATE TABLE it_sales.products_bak_2025_02_07 AS SELECT * FROM products;

-- Update table to add new columns
ALTER TABLE it_sales.products ADD COLUMN `product_brand` varchar(255) AFTER `product_name`;
ALTER TABLE it_sales.products ADD INDEX `product_brand_idx` (`product_brand`);

ALTER TABLE it_sales.products ADD COLUMN `product_type` varchar(255) AFTER `product_brand`;
ALTER TABLE it_sales.products ADD INDEX `product_type_idx` (`product_type`);

ALTER TABLE it_sales.products ADD COLUMN `product_model` varchar(255) AFTER `product_type`;

DESC products;

-- Populate new columns
UPDATE
    products
SET
    product_brand = CASE
        WHEN product_name LIKE 'Western %' THEN "Western Digital"
        ELSE substring_index(product_name, ' ', 1)
    END,
    product_type = CASE
        WHEN product_name LIKE 'Western %' THEN 'Storage'
        ELSE SUBSTRING_INDEX(SUBSTRING_INDEX(product_name, ' ', 2), ' ',-1)
    END,
    product_model = SUBSTRING_INDEX(product_name,' ',-1);

SELECT * FROM products;