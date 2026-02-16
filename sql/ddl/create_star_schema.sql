-- 1. DIM_DATE — Calendar dimension (populated via Python)
DROP TABLE IF EXISTS dim_date CASCADE;
CREATE TABLE dim_date (
    date_key            INTEGER PRIMARY KEY,
    full_date           DATE NOT NULL UNIQUE,
    year                SMALLINT NOT NULL,
    quarter             SMALLINT NOT NULL,
    month               SMALLINT NOT NULL,
    month_name          VARCHAR(20) NOT NULL,
    day_of_month        SMALLINT NOT NULL,
    day_of_week         SMALLINT NOT NULL,
    day_name            VARCHAR(20) NOT NULL,
    week_of_year        SMALLINT NOT NULL,
    is_weekend          BOOLEAN NOT NULL,
    fiscal_year         SMALLINT NOT NULL,
    fiscal_quarter      SMALLINT NOT NULL
);

-- 2. DIM_CUSTOMER — Customer dimension with geographic info
DROP TABLE IF EXISTS dim_customer CASCADE;
CREATE TABLE dim_customer (
    customer_key            SERIAL PRIMARY KEY,
    customer_id             VARCHAR(50) NOT NULL,
    customer_unique_id      VARCHAR(50) NOT NULL,
    customer_zip_code       VARCHAR(10),
    customer_city           VARCHAR(100),
    customer_state          VARCHAR(5)
);
CREATE INDEX idx_dim_customer_id ON dim_customer(customer_id);
CREATE INDEX idx_dim_customer_unique ON dim_customer(customer_unique_id);

-- 3. DIM_PRODUCT — Product dimension with category translation
DROP TABLE IF EXISTS dim_product CASCADE;
CREATE TABLE dim_product (
    product_key                 SERIAL PRIMARY KEY,
    product_id                  VARCHAR(50) NOT NULL UNIQUE,
    category_name_pt            VARCHAR(100),
    category_name_en            VARCHAR(100),
    product_name_length         INTEGER,
    product_description_length  INTEGER,
    product_photos_qty          INTEGER,
    product_weight_g            NUMERIC(10,2),
    product_length_cm           NUMERIC(10,2),
    product_height_cm           NUMERIC(10,2),
    product_width_cm            NUMERIC(10,2)
);
CREATE INDEX idx_dim_product_id ON dim_product(product_id);
CREATE INDEX idx_dim_product_category ON dim_product(category_name_en);

-- 4. DIM_SELLER — Seller/Vendor dimension
DROP TABLE IF EXISTS dim_seller CASCADE;
CREATE TABLE dim_seller (
    seller_key          SERIAL PRIMARY KEY,
    seller_id           VARCHAR(50) NOT NULL UNIQUE,
    seller_zip_code     VARCHAR(10),
    seller_city         VARCHAR(100),
    seller_state        VARCHAR(5)
);
CREATE INDEX idx_dim_seller_id ON dim_seller(seller_id);

-- 5. DIM_GEOGRAPHY — Deduplicated geolocation by zip code
DROP TABLE IF EXISTS dim_geography CASCADE;
CREATE TABLE dim_geography (
    geo_key                     SERIAL PRIMARY KEY,
    zip_code_prefix             VARCHAR(10) NOT NULL UNIQUE,
    latitude                    NUMERIC(12,8),
    longitude                   NUMERIC(12,8),
    city                        VARCHAR(100),
    state                       VARCHAR(5)
);
CREATE INDEX idx_dim_geo_zip ON dim_geography(zip_code_prefix);
CREATE INDEX idx_dim_geo_state ON dim_geography(state);

-- 6. DIM_PAYMENT_TYPE — Payment method dimension (Junk Dimension)
DROP TABLE IF EXISTS dim_payment_type CASCADE;
CREATE TABLE dim_payment_type (
    payment_type_key    SERIAL PRIMARY KEY,
    payment_type        VARCHAR(30) NOT NULL UNIQUE
);

-- 7. DIM_ORDER_STATUS — Order status dimension (Junk Dimension)
DROP TABLE IF EXISTS dim_order_status CASCADE;
CREATE TABLE dim_order_status (
    status_key          SERIAL PRIMARY KEY,
    order_status        VARCHAR(30) NOT NULL UNIQUE
);

-- FACT_ORDERS — Grain: one row per order item
-- Central fact table connecting sales, logistics, and customer behavior
DROP TABLE IF EXISTS fact_orders CASCADE;
CREATE TABLE fact_orders (
    order_item_key              SERIAL PRIMARY KEY,
    order_id                    VARCHAR(50) NOT NULL,
    order_item_id               INTEGER NOT NULL,

    -- Dimension Foreign Keys
    purchase_date_key           INTEGER REFERENCES dim_date(date_key),
    delivery_date_key           INTEGER REFERENCES dim_date(date_key),
    estimated_delivery_date_key INTEGER REFERENCES dim_date(date_key),
    customer_key                INTEGER REFERENCES dim_customer(customer_key),
    product_key                 INTEGER REFERENCES dim_product(product_key),
    seller_key                  INTEGER REFERENCES dim_seller(seller_key),
    status_key                  INTEGER REFERENCES dim_order_status(status_key),

    -- Measures: Financial
    price                       NUMERIC(12,2) NOT NULL,
    shipping_cost               NUMERIC(12,2) NOT NULL,
    total_order_value           NUMERIC(12,2) NOT NULL,

    -- Measures: Logistics
    purchase_timestamp          TIMESTAMP,
    delivered_timestamp         TIMESTAMP,
    estimated_delivery_date     TIMESTAMP,
    delivery_days_actual        INTEGER,
    delivery_days_estimated     INTEGER,
    delivery_delay_days         INTEGER,
    is_late_delivery            BOOLEAN,

    -- Measures: Review
    review_score                SMALLINT,

    -- Degenerate Dimension
    order_status_raw            VARCHAR(30)
);
CREATE INDEX idx_fact_orders_order ON fact_orders(order_id);
CREATE INDEX idx_fact_orders_purchase_date ON fact_orders(purchase_date_key);
CREATE INDEX idx_fact_orders_customer ON fact_orders(customer_key);
CREATE INDEX idx_fact_orders_product ON fact_orders(product_key);
CREATE INDEX idx_fact_orders_seller ON fact_orders(seller_key);

-- FACT_PAYMENTS — Grain: one row per payment transaction
-- Supports analysis of payment behavior and installment patterns
DROP TABLE IF EXISTS fact_payments CASCADE;
CREATE TABLE fact_payments (
    payment_key             SERIAL PRIMARY KEY,
    order_id                VARCHAR(50) NOT NULL,

    -- Dimension Foreign Keys
    purchase_date_key       INTEGER REFERENCES dim_date(date_key),
    customer_key            INTEGER REFERENCES dim_customer(customer_key),
    payment_type_key        INTEGER REFERENCES dim_payment_type(payment_type_key),

    -- Measures
    payment_sequential      INTEGER NOT NULL,
    payment_installments    INTEGER NOT NULL,
    payment_value           NUMERIC(12,2) NOT NULL
);
CREATE INDEX idx_fact_payments_order ON fact_payments(order_id);
CREATE INDEX idx_fact_payments_date ON fact_payments(purchase_date_key);
CREATE INDEX idx_fact_payments_customer ON fact_payments(customer_key);

DROP TABLE IF EXISTS stg_orders CASCADE;
CREATE TABLE stg_orders (
    order_id                        VARCHAR(50),
    customer_id                     VARCHAR(50),
    order_status                    VARCHAR(30),
    order_purchase_timestamp        VARCHAR(30),
    order_approved_at               VARCHAR(30),
    order_delivered_carrier_date    VARCHAR(30),
    order_delivered_customer_date   VARCHAR(30),
    order_estimated_delivery_date   VARCHAR(30)
);

DROP TABLE IF EXISTS stg_order_items CASCADE;
CREATE TABLE stg_order_items (
    order_id            VARCHAR(50),
    order_item_id       INTEGER,
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date VARCHAR(30),
    price               NUMERIC(12,2),
    freight_value       NUMERIC(12,2)
);

DROP TABLE IF EXISTS stg_customers CASCADE;
CREATE TABLE stg_customers (
    customer_id             VARCHAR(50),
    customer_unique_id      VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city           VARCHAR(100),
    customer_state          VARCHAR(5)
);

DROP TABLE IF EXISTS stg_products CASCADE;
CREATE TABLE stg_products (
    product_id                  VARCHAR(50),
    product_category_name       VARCHAR(100),
    product_name_lenght         INTEGER,
    product_description_lenght  INTEGER,
    product_photos_qty          INTEGER,
    product_weight_g            NUMERIC(10,2),
    product_length_cm           NUMERIC(10,2),
    product_height_cm           NUMERIC(10,2),
    product_width_cm            NUMERIC(10,2)
);

DROP TABLE IF EXISTS stg_sellers CASCADE;
CREATE TABLE stg_sellers (
    seller_id               VARCHAR(50),
    seller_zip_code_prefix  VARCHAR(10),
    seller_city             VARCHAR(100),
    seller_state            VARCHAR(5)
);

DROP TABLE IF EXISTS stg_payments CASCADE;
CREATE TABLE stg_payments (
    order_id                VARCHAR(50),
    payment_sequential      INTEGER,
    payment_type            VARCHAR(30),
    payment_installments    INTEGER,
    payment_value           NUMERIC(12,2)
);

DROP TABLE IF EXISTS stg_reviews CASCADE;
CREATE TABLE stg_reviews (
    review_id                   VARCHAR(50),
    order_id                    VARCHAR(50),
    review_score                SMALLINT,
    review_comment_title        TEXT,
    review_comment_message      TEXT,
    review_creation_date        VARCHAR(30),
    review_answer_timestamp     VARCHAR(30)
);

DROP TABLE IF EXISTS stg_geolocation CASCADE;
CREATE TABLE stg_geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat             NUMERIC(12,8),
    geolocation_lng             NUMERIC(12,8),
    geolocation_city            VARCHAR(100),
    geolocation_state           VARCHAR(5)
);

DROP TABLE IF EXISTS stg_category_translation CASCADE;
CREATE TABLE stg_category_translation (
    product_category_name           VARCHAR(100),
    product_category_name_english   VARCHAR(100)
);