-- Version 1.0, Last Modified: 2025-02-05
-- This script is Exploratory Data Analysis (EDA).


/*
 * Objectives:
 * [X -- line 11] 1. Data type validation
 * 2. Data overview
 * 3. Check for duplicates
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