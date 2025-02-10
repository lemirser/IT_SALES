# IT Equipment Sales Analysis (SQL Project)

## Overview

This project focuses on analyzing IT equipment sales using SQL. The dataset contains information about customers, products, sales transactions, and order details. The main goal is to perform **RFM (Recency, Frequency, Monetary)** analysis to segment customers and gain insights into purchasing patterns.

## Objectives

1. **Data Cleaning & Preparation:** Handle missing values, duplicates, and inconsistencies.

2. **Sales Trends Analysis:** Identify top-selling products, revenue trends, and customer purchasing behavior.

3. **Customer Segmentation (RFM Analysis):** Categorize customers based on their purchase history.

4. **Performance Optimization:** Use indexing, partitioning, and efficient SQL queries.

5. **Data Visualization (Optional):** Create dashboards using Looker Studio, Tableau, or Power BI.

6. **Calculate Key Performance Indicators (KPIs):** Analyze essential business metrics such as:

    - **Revenue:** The total sales generated over a given period.

    - **Customer Lifetime Value (CLV):** The total revenue a business can expect from a single customer over their engagement period.

    - **Churn Rate:** The percentage of customers who stop purchasing over a specific timeframe, indicating customer retention effectiveness.

    - **Product Profitability:** The profit margin of individual products, calculated by comparing sales revenue against the cost of goods sold (COGS).

---

## Dataset Description

This dataset consists of four tables:

### 1. `customers` (Customer Information)
Contains details of customers who made purchases.

| Column Name  | Data Type | Description |
| ------------ | --------- | ----------- |
| `customer_id`  | INT | Unique ID for each customer |
| `customer_name`  | TEXT | Full name of the customer|
| `email`  | TEXT | Email address |
| `phone`  | TEXT | Contact number |
| `city`  | TEXT | City of residence |
| `state`  | TEXT | State of residence |
| `country`  | TEXT | Country of residence |
| `registration_date`  | DATE | Date customer registered|

### 2. `products` (IT Equipment Details)
Contains information about IT products available for sale.

| Column Name  | Data Type | Description |
| ------------ | --------- | ----------- |
| `product_id`  | INT | Unique product ID |
| `product_name`  | TEXT | Name of the IT equipment |
| `category`  | TEXT | Product category (Laptop, Monitor, Accessories, etc.) |
| `brand`  | TEXT | Brand of the product |
| `price`  | DECIMAL | Selling price of the product |
| `stock_quantity`  | INT | Available stock count |

### 3. `orders` (Customer Purchases)
Records of customer transactions.

| Column Name  | Data Type | Description |
| ------------ | --------- | ----------- |
| `order_id`  | INT | Unique sales order ID |
| `customer_id`  | INT | Customer who made the order |
| `order_date`  | DATE | Date of the order |
| `total_price`  | DECIMAL | Total cost of the order |
| `payment_method`  | TEXT | Payment type |
| `status`  | TEXT | Order status |

### 4. `order_details` (Product in Each Order)
Details of the products sold in each order.

| Column Name  | Data Type | Description |
| ------------ | --------- | ----------- |
| `order_id`  | INT | Sales order ID |
| `product_id`  | INT | Product Sold |
| `quantity`  | INT | Quantity of the product sold |
| `unit_price`  | DECIMAL | Price per unit at the time of sale |
| `subtotal`  | DECIMAL | Total cost of the product |

---

## SQL Queries for Analysis
### 1. Data cleaning
Check for missing values and inconsistencies.
```sql
-- Check for orders without order details
SELECT
    o.order_id o_order_id,
    od.order_id od_order_id
FROM
    orders o
LEFT JOIN order_details od
ON o.order_id = od.order_id
WHERE od.order_id IS NULL;
```

### 2. Sales Trend Analysis
Find monthly revenue trends.
```sql
-- Monthly
-- Based on the report below, the 2024-12 has the highest sales and orders.
SELECT
    LEFT(order_date,7) `YYYY-MM`,
    -- DATE_FORMAT(order_date, '%Y-%m') `YYYY-MM`,
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
```

### 3. Revenue per Product
Find the revenue per product
```sql
-- Based on the result of the query, the Monitor sales have the highest sales every year.

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
```
### 4. Sales Growth Rate
Find the fluctuation or changes in monthly sales.
```sql
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
```

### 5. Average Revenue Per Unit
Help measure product value and pricing effectiveness
```sql
/*
 * With avpu, we can check which product yield a higher revenue sales per month/year.
 * We can also decide to run a discount sale or marketing ad during the month with the highest avg sale per product
 */
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
```
### 6. Customer RFM Analysis
Check the recency, frequency, and monetary values. This can help identify the best customers and perform targeted marketing campaigns.
```sql
WITH rfm AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_purchase, -- Recency
        COUNT(order_id) AS frequency,    -- Frequency
        SUM(unit_price) AS monetary     -- Monetary
    FROM orders
    WHERE status IN ('Completed','Pending')
    GROUP BY customer_id
)
SELECT
    customer_id,
    DATEDIFF(CURRENT_DATE(), last_purchase) AS recency, -- Count the days the customer LAST ordered
    frequency,
    monetary
FROM rfm
ORDER BY recency ASC, monetary DESC;
```

Assign RFM Scores (1-5 scale)
```sql
/*
 * Example of customer types with rfm scores:
 *
 * Whales: The biggest customers with high (5,5,5) values in all three factors that should be targeted with special promotions to keep them active.
 * New Customers: Customers with high recency and low frequency (5,1,X) are new customers. A targeted follow-up may convert them into repeat customers.
 * Lapsed customers: Customers with low recency but high value (1,X,5) were once valuable customers but have since stopped. A targeted message may reactivate them.
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
```

---

## Installation and Setup
1. **Download Dataset Files**
    * [Customers Data](/csvs/customers.csv)
    * [Products Data](/csvs/products.csv)
    * [Order Details Data](/csvs/sales_order_details.csv)
    * [Orders Data](/csvs/sales_orders.csv)

2. **Import Data into SQL Database**

Load data using your database's import tool
```sql
CREATE SCHEMA `it_sales`;

USE it_sales;

DROP TABLE IF EXISTS customer;
CREATE TABLE customer (
`customer_id` int NOT NULL AUTO_INCREMENT,
`customer_name` varchar(255) NOT NULL,
`email` varchar(255),
`phone_num` varchar(255),
`city` varchar(255),
`state` char(2),
`country` char(3),
`registration_date` date,
PRIMARY KEY (`customer_id`)
);

DROP TABLE IF EXISTS products;
CREATE TABLE products (
`product_id` int NOT NULL AUTO_INCREMENT,
`product_name` varchar(255),
`category` varchar(255),
`brand` varchar(255),
`price` decimal(10,2),
`stock_quantity` SMALLINT,
PRIMARY KEY (`product_id`),
INDEX `category_idx` (`category`),
INDEX `brand_idx` (`brand`)
);

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
`order_id` int NOT NULL AUTO_INCREMENT,
`customer_id` int,
`order_date` date,
`total_price` decimal(10,2),
`payment_method` varchar(20),
`status` varchar(15),
PRIMARY KEY (`order_id`),
FOREIGN KEY (`customer_id`) REFERENCES customer(`customer_id`),
INDEX `payment_method_id` (`payment_method`),
INDEX `status_idx` (`status`)
);

DROP TABLE IF EXISTS order_details;
CREATE TABLE order_details (
`order_id` int,
`product_id` int,
`quantity` TINYINT,
`unit_price` decimal(10,2),
`subtotal` decimal(10,2),
FOREIGN KEY (`order_id`) REFERENCES orders(`order_id`),
FOREIGN KEY (`product_id`) REFERENCES products(`product_id`)
);
```
3. **Run Queries to analyze sales and customer behavior.**