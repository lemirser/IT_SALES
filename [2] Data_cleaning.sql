-- Version 1.0, Last Modified: 2025-02-04
-- This script is for data cleaning.


/*
 * Objectives:
 * [X] 1. Correct the unit price in order_details, set the correct unit price based from product_id from the products table.
 * 2. Update the subtotal in order_details, multiply unit_price and quantity.
 * 3. update the total_price in orders table base on the subtotal.
 * 4. add new column in products, unit_cost (unit_price/(1+25%).
 * 5. Update the price column in products to unit_price.
 */

USE it_sales;
##### ##### #####
# 1. Correct the unit price in order_details, set the correct unit price based from product_id from the products table.

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