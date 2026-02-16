import sys
import os
import time
import pandas as pd
from sqlalchemy import text

sys.path.insert(0, os.path.dirname(__file__))
from utils import (
    get_engine, validate_dataframe, log_step,
    generate_dim_date, truncate_table, get_row_count, logger,
    psql_insert_copy
)

RAW_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'raw')

CSV_TO_STAGING = {
    'olist_orders_dataset.csv':             'stg_orders',
    'olist_order_items_dataset.csv':        'stg_order_items',
    'olist_customers_dataset.csv':          'stg_customers',
    'olist_products_dataset.csv':           'stg_products',
    'olist_sellers_dataset.csv':            'stg_sellers',
    'olist_order_payments_dataset.csv':     'stg_payments',
    'olist_order_reviews_dataset.csv':      'stg_reviews',
    'olist_geolocation_dataset.csv':        'stg_geolocation',
    'product_category_name_translation.csv':'stg_category_translation',
}


def phase_extract(engine):
    log_step('PHASE 1: EXTRACT', 'START', 'Loading CSVs via Fast COPY method')
    reports = []

    for csv_file, table_name in CSV_TO_STAGING.items():
        file_path = os.path.join(RAW_PATH, csv_file)
        if not os.path.exists(file_path):
            log_step(f'  Load {csv_file}', 'FAIL', 'File not found')
            continue

        start = time.time()
        df = pd.read_csv(file_path, low_memory=False)
        report = validate_dataframe(df, table_name)
        reports.append(report)

        df.to_sql(table_name, engine, if_exists='replace', index=False, method=psql_insert_copy)
        elapsed = time.time() - start
        log_step(f'  Load {csv_file}', 'DONE', f'{len(df):,} rows -> {table_name} ({elapsed:.1f}s)')

    log_step('PHASE 1: EXTRACT', 'DONE', f'{len(reports)} tables loaded')
    return reports


def phase_transform_load(engine):
    log_step('PHASE 2+3: TRANSFORM & LOAD', 'START', 'Building dimension and fact tables')

    _load_dim_date(engine)
    _load_dim_customer(engine)
    _load_dim_product(engine)
    _load_dim_seller(engine)
    _load_dim_geography(engine)
    _load_dim_payment_type(engine)
    _load_dim_order_status(engine)
    _load_fact_orders(engine)
    _load_fact_payments(engine)

    log_step('PHASE 2+3: TRANSFORM & LOAD', 'DONE', 'All dimension and fact tables populated')


def _load_dim_date(engine):
    log_step('  dim_date', 'START')
    df = generate_dim_date('2016-01-01', '2019-12-31')
    truncate_table(engine, 'dim_date')
    df.to_sql('dim_date', engine, if_exists='append', index=False, method=psql_insert_copy)
    log_step('  dim_date', 'DONE', f'{len(df):,} rows')


def _load_dim_customer(engine):
    log_step('  dim_customer', 'START')
    query = """
        INSERT INTO dim_customer (customer_id, customer_unique_id, customer_zip_code, customer_city, customer_state)
        SELECT
            customer_id,
            customer_unique_id,
            customer_zip_code_prefix,
            LOWER(TRIM(customer_city)),
            UPPER(TRIM(customer_state))
        FROM stg_customers
    """
    truncate_table(engine, 'dim_customer')
    with engine.connect() as conn:
        conn.execute(text(query))
        conn.commit()
    count = get_row_count(engine, 'dim_customer')
    log_step('  dim_customer', 'DONE', f'{count:,} rows')


def _load_dim_product(engine):
    log_step('  dim_product', 'START')
    query = """
        INSERT INTO dim_product (
            product_id, category_name_pt, category_name_en,
            product_name_length, product_description_length, product_photos_qty,
            product_weight_g, product_length_cm, product_height_cm, product_width_cm
        )
        SELECT
            p.product_id,
            p.product_category_name,
            COALESCE(t.product_category_name_english, p.product_category_name),
            p.product_name_lenght,
            p.product_description_lenght,
            p.product_photos_qty,
            p.product_weight_g,
            p.product_length_cm,
            p.product_height_cm,
            p.product_width_cm
        FROM stg_products p
        LEFT JOIN stg_category_translation t
            ON p.product_category_name = t.product_category_name
    """
    truncate_table(engine, 'dim_product')
    with engine.connect() as conn:
        conn.execute(text(query))
        conn.commit()
    count = get_row_count(engine, 'dim_product')
    log_step('  dim_product', 'DONE', f'{count:,} rows')


def _load_dim_seller(engine):
    log_step('  dim_seller', 'START')
    query = """
        INSERT INTO dim_seller (seller_id, seller_zip_code, seller_city, seller_state)
        SELECT
            seller_id,
            seller_zip_code_prefix,
            LOWER(TRIM(seller_city)),
            UPPER(TRIM(seller_state))
        FROM stg_sellers
    """
    truncate_table(engine, 'dim_seller')
    with engine.connect() as conn:
        conn.execute(text(query))
        conn.commit()
    count = get_row_count(engine, 'dim_seller')
    log_step('  dim_seller', 'DONE', f'{count:,} rows')


def _load_dim_geography(engine):
    log_step('  dim_geography', 'START')
    query = """
        INSERT INTO dim_geography (zip_code_prefix, latitude, longitude, city, state)
        SELECT DISTINCT ON (geolocation_zip_code_prefix)
            geolocation_zip_code_prefix,
            geolocation_lat,
            geolocation_lng,
            LOWER(TRIM(geolocation_city)),
            UPPER(TRIM(geolocation_state))
        FROM stg_geolocation
        ORDER BY geolocation_zip_code_prefix
    """
    truncate_table(engine, 'dim_geography')
    with engine.connect() as conn:
        conn.execute(text(query))
        conn.commit()
    count = get_row_count(engine, 'dim_geography')
    log_step('  dim_geography', 'DONE', f'{count:,} rows')


def _load_dim_payment_type(engine):
    log_step('  dim_payment_type', 'START')
    query = """
        INSERT INTO dim_payment_type (payment_type)
        SELECT DISTINCT payment_type
        FROM stg_payments
        WHERE payment_type IS NOT NULL
        ORDER BY payment_type
    """
    truncate_table(engine, 'dim_payment_type')
    with engine.connect() as conn:
        conn.execute(text(query))
        conn.commit()
    count = get_row_count(engine, 'dim_payment_type')
    log_step('  dim_payment_type', 'DONE', f'{count:,} rows')


def _load_dim_order_status(engine):
    log_step('  dim_order_status', 'START')
    query = """
        INSERT INTO dim_order_status (order_status)
        SELECT DISTINCT order_status
        FROM stg_orders
        WHERE order_status IS NOT NULL
        ORDER BY order_status
    """
    truncate_table(engine, 'dim_order_status')
    with engine.connect() as conn:
        conn.execute(text(query))
        conn.commit()
    count = get_row_count(engine, 'dim_order_status')
    log_step('  dim_order_status', 'DONE', f'{count:,} rows')


def _load_fact_orders(engine):
    log_step('  fact_orders', 'START')

    log_step('  fact_orders — creating staging indexes', 'START')
    with engine.connect() as conn:
        conn.execute(text("CREATE INDEX IF NOT EXISTS idx_stg_reviews_order ON stg_reviews(order_id)"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS idx_stg_orders_order ON stg_orders(order_id)"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS idx_stg_orders_customer ON stg_orders(customer_id)"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS idx_stg_items_order ON stg_order_items(order_id)"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS idx_stg_items_product ON stg_order_items(product_id)"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS idx_stg_items_seller ON stg_order_items(seller_id)"))
        conn.commit()
    log_step('  fact_orders — creating staging indexes', 'DONE')

    query = """
        WITH review_dedup AS (
            SELECT DISTINCT ON (order_id)
                order_id,
                review_score
            FROM stg_reviews
            ORDER BY order_id, review_creation_date DESC
        )
        INSERT INTO fact_orders (
            order_id, order_item_id,
            purchase_date_key, delivery_date_key, estimated_delivery_date_key,
            customer_key, product_key, seller_key, status_key,
            price, shipping_cost, total_order_value,
            purchase_timestamp, delivered_timestamp, estimated_delivery_date,
            delivery_days_actual, delivery_days_estimated, delivery_delay_days,
            is_late_delivery, review_score, order_status_raw
        )
        SELECT
            oi.order_id,
            oi.order_item_id,

            CAST(TO_CHAR(o.order_purchase_timestamp::timestamp, 'YYYYMMDD') AS INTEGER),
            CASE WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_delivered_customer_date != ''
                 THEN CAST(TO_CHAR(o.order_delivered_customer_date::timestamp, 'YYYYMMDD') AS INTEGER)
                 ELSE NULL END,
            CASE WHEN o.order_estimated_delivery_date IS NOT NULL AND o.order_estimated_delivery_date != ''
                 THEN CAST(TO_CHAR(o.order_estimated_delivery_date::timestamp, 'YYYYMMDD') AS INTEGER)
                 ELSE NULL END,

            dc.customer_key,
            dp.product_key,
            ds.seller_key,
            dos.status_key,

            oi.price,
            oi.freight_value,
            (oi.price + oi.freight_value),

            o.order_purchase_timestamp::timestamp,
            CASE WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_delivered_customer_date != ''
                 THEN o.order_delivered_customer_date::timestamp ELSE NULL END,
            CASE WHEN o.order_estimated_delivery_date IS NOT NULL AND o.order_estimated_delivery_date != ''
                 THEN o.order_estimated_delivery_date::timestamp ELSE NULL END,

            CASE WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_delivered_customer_date != ''
                 THEN EXTRACT(DAY FROM (o.order_delivered_customer_date::timestamp - o.order_purchase_timestamp::timestamp))::integer
                 ELSE NULL END,
            CASE WHEN o.order_estimated_delivery_date IS NOT NULL AND o.order_estimated_delivery_date != ''
                 THEN EXTRACT(DAY FROM (o.order_estimated_delivery_date::timestamp - o.order_purchase_timestamp::timestamp))::integer
                 ELSE NULL END,
            CASE WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_delivered_customer_date != ''
                      AND o.order_estimated_delivery_date IS NOT NULL AND o.order_estimated_delivery_date != ''
                 THEN EXTRACT(DAY FROM (o.order_delivered_customer_date::timestamp - o.order_estimated_delivery_date::timestamp))::integer
                 ELSE NULL END,
            CASE WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_delivered_customer_date != ''
                      AND o.order_estimated_delivery_date IS NOT NULL AND o.order_estimated_delivery_date != ''
                 THEN o.order_delivered_customer_date::timestamp > o.order_estimated_delivery_date::timestamp
                 ELSE NULL END,

            r.review_score,
            o.order_status

        FROM stg_order_items oi
        JOIN stg_orders o ON oi.order_id = o.order_id
        JOIN dim_customer dc ON o.customer_id = dc.customer_id
        JOIN dim_product dp ON oi.product_id = dp.product_id
        JOIN dim_seller ds ON oi.seller_id = ds.seller_id
        JOIN dim_order_status dos ON o.order_status = dos.order_status
        LEFT JOIN review_dedup r ON oi.order_id = r.order_id
    """
    truncate_table(engine, 'fact_orders')
    with engine.connect() as conn:
        conn.execute(text(query))
        conn.commit()
    count = get_row_count(engine, 'fact_orders')
    log_step('  fact_orders', 'DONE', f'{count:,} rows')


def _load_fact_payments(engine):
    log_step('  fact_payments', 'START')
    query = """
        INSERT INTO fact_payments (
            order_id, purchase_date_key, customer_key, payment_type_key,
            payment_sequential, payment_installments, payment_value
        )
        SELECT
            p.order_id,
            CAST(TO_CHAR(o.order_purchase_timestamp::timestamp, 'YYYYMMDD') AS INTEGER),
            dc.customer_key,
            pt.payment_type_key,
            p.payment_sequential,
            p.payment_installments,
            p.payment_value
        FROM stg_payments p
        JOIN stg_orders o ON p.order_id = o.order_id
        JOIN dim_customer dc ON o.customer_id = dc.customer_id
        JOIN dim_payment_type pt ON p.payment_type = pt.payment_type
    """
    truncate_table(engine, 'fact_payments')
    with engine.connect() as conn:
        conn.execute(text(query))
        conn.commit()
    count = get_row_count(engine, 'fact_payments')
    log_step('  fact_payments', 'DONE', f'{count:,} rows')


def print_summary(engine):
    logger.info('DATA WAREHOUSE LOAD SUMMARY')
    tables = [
        'dim_date', 'dim_customer', 'dim_product', 'dim_seller',
        'dim_geography', 'dim_payment_type', 'dim_order_status',
        'fact_orders', 'fact_payments'
    ]
    for t in tables:
        try:
            count = get_row_count(engine, t)
            logger.info(f'  {t:30s} : {count:>10,} rows')
        except Exception as e:
            logger.error(f'  {t:30s} : ERROR - {e}')


def main():
    total_start = time.time()
    logger.info('RETAIL360 ETL PIPELINE — START')

    engine = get_engine()

    phase_extract(engine)
    phase_transform_load(engine)
    print_summary(engine)

    elapsed = time.time() - total_start
    logger.info(f'PIPELINE COMPLETED in {elapsed:.1f}s')


if __name__ == '__main__':
    main()