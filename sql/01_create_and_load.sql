-- =============================================================
-- 01_create_and_load.sql
-- Create the raw Instacart tables and load the original CSV files.
--
-- Run from the project root:
--   createdb instacart
--   psql -d instacart -f sql/01_create_and_load.sql
-- (expects the CSVs extracted from archive.zip into data/raw/)
-- =============================================================

DROP TABLE IF EXISTS order_products_prior;
DROP TABLE IF EXISTS order_products_train;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS aisles;
DROP TABLE IF EXISTS departments;

CREATE TABLE aisles (
    aisle_id   INT PRIMARY KEY,
    aisle      TEXT NOT NULL
);

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department    TEXT NOT NULL
);

CREATE TABLE products (
    product_id    INT PRIMARY KEY,
    product_name  TEXT NOT NULL,
    aisle_id      INT REFERENCES aisles (aisle_id),
    department_id INT REFERENCES departments (department_id)
);

-- One row per order. eval_set = 'prior', 'train' or 'test'.
-- days_since_prior_order is blank for a customer's first order
-- and is capped at 30 in the source data.
CREATE TABLE orders (
    order_id               INT PRIMARY KEY,
    user_id                INT NOT NULL,
    eval_set               TEXT NOT NULL,
    order_number           INT NOT NULL,
    order_dow              INT,
    order_hour_of_day      INT,
    days_since_prior_order NUMERIC(4,1)
);

-- One row per product in an order (the basket contents).
CREATE TABLE order_products_prior (
    order_id          INT NOT NULL,
    product_id        INT NOT NULL,
    add_to_cart_order INT,
    reordered         INT
);

CREATE TABLE order_products_train (
    order_id          INT NOT NULL,
    product_id        INT NOT NULL,
    add_to_cart_order INT,
    reordered         INT
);

\copy aisles               FROM 'data/raw/aisles.csv'               WITH (FORMAT csv, HEADER true)
\copy departments          FROM 'data/raw/departments.csv'          WITH (FORMAT csv, HEADER true)
\copy products             FROM 'data/raw/products.csv'             WITH (FORMAT csv, HEADER true)
\copy orders               FROM 'data/raw/orders.csv'               WITH (FORMAT csv, HEADER true)
\copy order_products_prior FROM 'data/raw/order_products__prior.csv' WITH (FORMAT csv, HEADER true)
\copy order_products_train FROM 'data/raw/order_products__train.csv' WITH (FORMAT csv, HEADER true)

CREATE INDEX idx_orders_user        ON orders (user_id);
CREATE INDEX idx_op_prior_order     ON order_products_prior (order_id);
CREATE INDEX idx_op_train_order     ON order_products_train (order_id);

ANALYZE;
