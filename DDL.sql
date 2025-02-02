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