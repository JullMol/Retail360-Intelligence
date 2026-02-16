# Data Dictionary — Retail360 Intelligence DWH

## Dimension Tables

### dim_date
Calendar dimension covering 2016–2019.

| Column | Type | Description |
|---|---|---|
| date_key | INTEGER (PK) | Surrogate key in YYYYMMDD format |
| full_date | DATE | Calendar date |
| year | SMALLINT | Calendar year |
| quarter | SMALLINT | Calendar quarter (1–4) |
| month | SMALLINT | Month number (1–12) |
| month_name | VARCHAR(20) | Full month name (e.g., January) |
| day_of_month | SMALLINT | Day of the month |
| day_of_week | SMALLINT | ISO day of week (1=Mon, 7=Sun) |
| day_name | VARCHAR(20) | Full day name |
| week_of_year | SMALLINT | Week number (0–53) |
| is_weekend | BOOLEAN | True if Saturday or Sunday |
| fiscal_year | SMALLINT | Fiscal year (Apr start) |
| fiscal_quarter | SMALLINT | Fiscal quarter |

---

### dim_customer
Customer dimension with geographic attributes.

| Column | Type | Description |
|---|---|---|
| customer_key | SERIAL (PK) | Surrogate key |
| customer_id | VARCHAR(50) | Original order-level customer ID |
| customer_unique_id | VARCHAR(50) | Deduplicated unique customer ID |
| customer_zip_code | VARCHAR(10) | Zip code prefix |
| customer_city | VARCHAR(100) | City (lowercase, trimmed) |
| customer_state | VARCHAR(5) | State abbreviation (uppercase) |

---

### dim_product
Product dimension with translated category names.

| Column | Type | Description |
|---|---|---|
| product_key | SERIAL (PK) | Surrogate key |
| product_id | VARCHAR(50) | Original product ID |
| category_name_pt | VARCHAR(100) | Category name in Portuguese |
| category_name_en | VARCHAR(100) | Category name in English |
| product_name_length | INTEGER | Character count of product name |
| product_description_length | INTEGER | Character count of description |
| product_photos_qty | INTEGER | Number of product photos |
| product_weight_g | NUMERIC(10,2) | Weight in grams |
| product_length_cm | NUMERIC(10,2) | Length in centimeters |
| product_height_cm | NUMERIC(10,2) | Height in centimeters |
| product_width_cm | NUMERIC(10,2) | Width in centimeters |

---

### dim_seller
Seller/Vendor dimension.

| Column | Type | Description |
|---|---|---|
| seller_key | SERIAL (PK) | Surrogate key |
| seller_id | VARCHAR(50) | Original seller ID |
| seller_zip_code | VARCHAR(10) | Seller zip code prefix |
| seller_city | VARCHAR(100) | City (lowercase, trimmed) |
| seller_state | VARCHAR(5) | State abbreviation (uppercase) |

---

### dim_geography
Deduplicated geolocation by zip code prefix.

| Column | Type | Description |
|---|---|---|
| geo_key | SERIAL (PK) | Surrogate key |
| zip_code_prefix | VARCHAR(10) | Unique zip code prefix |
| latitude | NUMERIC(12,8) | Latitude coordinate |
| longitude | NUMERIC(12,8) | Longitude coordinate |
| city | VARCHAR(100) | City name |
| state | VARCHAR(5) | State abbreviation |

---

### dim_payment_type
Junk dimension for payment methods.

| Column | Type | Description |
|---|---|---|
| payment_type_key | SERIAL (PK) | Surrogate key |
| payment_type | VARCHAR(30) | credit_card, boleto, voucher, debit_card |

---

### dim_order_status
Junk dimension for order lifecycle states.

| Column | Type | Description |
|---|---|---|
| status_key | SERIAL (PK) | Surrogate key |
| order_status | VARCHAR(30) | delivered, shipped, canceled, etc. |

---

## Fact Tables

### fact_orders
**Grain:** One row per order item. Central fact table connecting sales, logistics, and customer behavior.

| Column | Type | Description |
|---|---|---|
| order_item_key | SERIAL (PK) | Surrogate key |
| order_id | VARCHAR(50) | Degenerate dimension — original order ID |
| order_item_id | INTEGER | Item sequence within order |
| purchase_date_key | INTEGER (FK → dim_date) | Purchase date key |
| delivery_date_key | INTEGER (FK → dim_date) | Actual delivery date key |
| estimated_delivery_date_key | INTEGER (FK → dim_date) | Estimated delivery date key |
| customer_key | INTEGER (FK → dim_customer) | Customer dimension key |
| product_key | INTEGER (FK → dim_product) | Product dimension key |
| seller_key | INTEGER (FK → dim_seller) | Seller dimension key |
| status_key | INTEGER (FK → dim_order_status) | Order status dimension key |
| price | NUMERIC(12,2) | Item price (excl. shipping) |
| shipping_cost | NUMERIC(12,2) | Freight/shipping cost |
| total_order_value | NUMERIC(12,2) | price + shipping_cost |
| purchase_timestamp | TIMESTAMP | Full purchase timestamp |
| delivered_timestamp | TIMESTAMP | Full delivery timestamp |
| estimated_delivery_date | TIMESTAMP | Promised delivery date |
| delivery_days_actual | INTEGER | Days from purchase to delivery |
| delivery_days_estimated | INTEGER | Days from purchase to estimated delivery |
| delivery_delay_days | INTEGER | delivery_actual - delivery_estimated (positive = late) |
| is_late_delivery | BOOLEAN | True if delivered after estimated date |
| review_score | SMALLINT | Customer review (1–5) |
| order_status_raw | VARCHAR(30) | Raw order status string |

---

### fact_payments
**Grain:** One row per payment transaction. Supports installment and payment method analysis.

| Column | Type | Description |
|---|---|---|
| payment_key | SERIAL (PK) | Surrogate key |
| order_id | VARCHAR(50) | Original order ID |
| purchase_date_key | INTEGER (FK → dim_date) | Purchase date key |
| customer_key | INTEGER (FK → dim_customer) | Customer dimension key |
| payment_type_key | INTEGER (FK → dim_payment_type) | Payment type dimension key |
| payment_sequential | INTEGER | Sequence number for multi-payment orders |
| payment_installments | INTEGER | Number of installments |
| payment_value | NUMERIC(12,2) | Payment amount |
