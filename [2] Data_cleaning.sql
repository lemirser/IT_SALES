-- Version 1.03, Last Modified: 2025-02-04
-- This script is for data cleaning.


/*
 * Objectives:
 * [X -- line 17] 1. Correct the unit price in order_details, set the correct unit price based from product_id from the products table.
 * [X -- line 90] 2. Update the subtotal in order_details, multiply unit_price and quantity.
 * [X -- line 129] 3. Update the total_price in orders table base on the subtotal.
 * [X -- line 219] 3a. Change the total_price into unit_price in orders table.
 * [X -- line 224] 4. Add new column in products, unit_cost (unit_price/(1+25%).
 * 5. Update the price column in products to unit_price.
 * 6. Add has_order_details column in orders table for orders with missing order_details record in order_details table
 */

USE it_sales;
##### ##### #####
-- 1. Correct the unit price in order_details, set the correct unit price based from product_id from the products table.

# Create temp table to test out the query for data cleaning
CREATE TEMPORARY TABLE order_details_temp AS
SELECT
    *
FROM
    order_details od;

# Compare the price from the temp table and the products table
SELECT
    odt.product_id AS temp_product_id,
    p.product_id AS p_product_id,
    odt.unit_price AS temp_price,
    p.price AS p_price
FROM
    order_details_temp odt
LEFT JOIN
    products p
ON
    odt.product_id = p.product_id;

# DML to test query logic
UPDATE
    order_details_temp odt
LEFT JOIN
    products p
ON
    odt.product_id = p.product_id
SET odt.unit_price = p.price;

# Validate if the DML query is correct. The temp price and products price should be the same.
SELECT
    odt.product_id AS temp_product_id,
    p.product_id AS p_product_id,
    odt.unit_price AS temp_price,
    p.price AS p_price
FROM
    order_details_temp odt
LEFT JOIN
    products p
ON
    odt.product_id = p.product_id;

# Backup the original table before updating the column values
DROP TABLE IF EXISTS it_sales.order_details_bak_2025_02_03;
CREATE TABLE it_sales.order_details_bak_2025_02_03 AS SELECT * FROM order_details;

# Update the column
UPDATE
    order_details od
LEFT JOIN
    products p
ON
    od.product_id = p.product_id
SET od.unit_price = p.price;


# Data validation
SELECT
    od.product_id AS temp_product_id,
    p.product_id AS p_product_id,
    od.unit_price AS temp_price,
    p.price AS p_price
FROM
    order_details od
LEFT JOIN
    products p
ON
    od.product_id = p.product_id;


##### ##### #####
-- 2. Update the subtotal in order_details, multiply unit_price and quantity.

-- Verify the issue
SELECT
    *
    -- Incorrect vault FOR subtotal
FROM
    order_details od;

-- Create temp table to test the DML logic
CREATE TEMPORARY TABLE it_sales.order_details_temp AS
SELECT
    *
FROM
    it_sales.order_details od;

-- Recompute for the new_subtotal
SELECT
    quantity,
    unit_price,
    subtotal AS org_subtotal,
    quantity * unit_price AS new_subtotal
FROM
    it_sales.order_details_temp odt;

-- Update the subtotal column with the correct value
-- Since we have a backup of the original order_details table, we don't need to create it again. But in production, you need to backup the table before any update.
UPDATE
    it_sales.order_details
SET
    subtotal = (quantity * unit_price);

SELECT
    *
FROM
    it_sales.order_details od;


##### ##### #####
-- 3. update the total_price in orders table base on the subtotal from order_details table.

# Validation
SELECT
    o.order_id,
    od.order_id,
    o.unit_price o_unit_price,
    od.quantity od_quantity,
    od.unit_price od_unit_price,
    od.subtotal od_subtotal
FROM
    orders o
LEFT JOIN
    order_details od
ON
    o.order_id = od.order_id
WHERE
    o.order_id = 3279;


# Create temp table to check the DML logic
CREATE TEMPORARY TABLE it_sales.orders_temp AS SELECT * FROM orders;

WITH subtotal_recomp AS (
SELECT
    DISTINCT order_id,
    SUM(od.subtotal) OVER(PARTITION BY od.order_id) total_price
FROM
    order_details od)
UPDATE
    it_sales.orders_temp ot
INNER JOIN subtotal_recomp od ON -- INNER JOIN so the missing orders IN order_details TABLE will be excluded IN the UPDATE.
    ot.order_id = od.order_id
SET
    ot.total_price = od.total_price;

SELECT
    o.order_id,
    od.order_id,
    o.unit_price o_total_price,
    SUM(od.subtotal) OVER(PARTITION BY od.order_id) correct_total,
    od.quantity od_quantity,
    od.unit_price od_unit_price,
    od.subtotal od_subtotal
FROM
    orders_temp o
LEFT JOIN
    order_details od
ON
    o.order_id = od.order_id
ORDER BY
    o.order_id ASC;


# Update the total_price value
CREATE TABLE it_sales.orders_bak_2025_02_04 AS SELECT * FROM it_sales.orders;

WITH subtotal_recomp AS (
SELECT
    DISTINCT order_id,
    SUM(od.subtotal) OVER(PARTITION BY od.order_id) total_price
FROM
    order_details od)
UPDATE
    it_sales.orders ot
INNER JOIN subtotal_recomp od ON
    ot.order_id = od.order_id
SET
    ot.total_price = od.total_price;

SELECT
    o.order_id,
    od.order_id,
    o.unit_price o_total_price,
    SUM(od.subtotal) OVER(PARTITION BY od.order_id) correct_total,
    od.quantity od_quantity,
    od.unit_price od_unit_price,
    od.subtotal od_subtotal
FROM
    orders o
LEFT JOIN
    order_details od
ON
    o.order_id = od.order_id
ORDER BY
    o.order_id ASC;


##### ##### #####
-- 3a. Change the total_price into unit_price in orders table.
ALTER TABLE it_sales.orders CHANGE total_price unit_price decimal(10,2);
DESC it_sales.orders;


##### ##### #####
-- 4. Add new column in products, unit_cost (unit_price/(1+25%).
ALTER TABLE it_sales.products ADD COLUMN unit_cost decimal(10,2) AFTER price;

DESC products;

CREATE TABLE it_sales.products_bak_2025_02_04 AS SELECT * FROM it_sales.products;


-- (1+.25) IS FOR the 25% markup
UPDATE
    it_sales.products p
SET
    unit_cost = (unit_price /(1 +.25));

SELECT
    product_id,
    price,
    unit_cost,
    price /(1 +.25) comp_cost
FROM
    products;