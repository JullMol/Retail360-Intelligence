CREATE OR REPLACE VIEW vw_executive_summary AS
SELECT
    dd.year,
    dd.quarter,
    dd.month,
    dd.month_name,
    COUNT(DISTINCT fo.order_id)                 AS total_orders,
    COUNT(DISTINCT dc.customer_unique_id)       AS unique_customers,
    SUM(fo.price)                                AS gross_revenue,
    SUM(fo.shipping_cost)                       AS total_shipping_cost,
    SUM(fo.total_order_value)                   AS net_revenue,
    ROUND(AVG(fo.total_order_value), 2)         AS avg_order_value,
    ROUND(AVG(fo.review_score), 2)              AS avg_satisfaction_score,
    SUM(CASE WHEN fo.is_late_delivery THEN 1 ELSE 0 END) AS late_deliveries,
    ROUND(
        (1 - SUM(CASE WHEN fo.is_late_delivery THEN 1 ELSE 0 END)::numeric
            / NULLIF(COUNT(CASE WHEN fo.delivered_timestamp IS NOT NULL THEN 1 END), 0)) * 100, 2
    ) AS on_time_delivery_rate,
    ROUND(SUM(fo.shipping_cost) / NULLIF(SUM(fo.total_order_value), 0) * 100, 2)
        AS shipping_cost_ratio
FROM fact_orders fo
JOIN dim_date dd ON fo.purchase_date_key = dd.date_key
JOIN dim_customer dc ON fo.customer_key = dc.customer_key
WHERE fo.order_status_raw = 'delivered'
GROUP BY dd.year, dd.quarter, dd.month, dd.month_name
ORDER BY dd.year, dd.month;

CREATE OR REPLACE VIEW vw_customer_segments AS
SELECT
    customer_unique_id,
    customer_city,
    customer_state,
    recency_days,
    frequency,
    monetary,
    avg_order_value,
    distinct_categories,
    r_score,
    f_score,
    m_score,
    rfm_score,
    customer_segment,
    CASE
        WHEN customer_segment IN ('Champions', 'Loyal Customers') THEN 'High Value'
        WHEN customer_segment IN ('Potential Loyalists', 'New Customers', 'Promising') THEN 'Growth'
        WHEN customer_segment IN ('At Risk', 'About to Sleep', 'Cannot Lose Them') THEN 'At Risk'
        ELSE 'Low Priority'
    END AS segment_group,
    CASE
        WHEN customer_segment IN ('Champions', 'Loyal Customers') THEN 'Reward & Retain'
        WHEN customer_segment = 'New Customers' THEN 'Onboarding Campaign'
        WHEN customer_segment = 'Potential Loyalists' THEN 'Upsell & Cross-sell'
        WHEN customer_segment IN ('At Risk', 'About to Sleep') THEN 'Win-back Campaign'
        WHEN customer_segment = 'Cannot Lose Them' THEN 'Urgent Retention'
        WHEN customer_segment = 'Hibernating' THEN 'Re-engagement Email'
        ELSE 'General Marketing'
    END AS recommended_action
FROM view_rfm_segmentation;

CREATE OR REPLACE VIEW vw_geo_performance AS
SELECT
    dc.customer_state                                          AS state,
    dg.latitude                                                 AS avg_latitude,
    dg.longitude                                                AS avg_longitude,
    COUNT(DISTINCT fo.order_id)                                AS total_orders,
    COUNT(DISTINCT dc.customer_unique_id)                      AS unique_customers,
    SUM(fo.total_order_value)                                  AS total_revenue,
    ROUND(AVG(fo.total_order_value), 2)                        AS avg_order_value,
    ROUND(AVG(fo.delivery_days_actual), 1)                     AS avg_delivery_days,
    ROUND(
        SUM(CASE WHEN fo.is_late_delivery THEN 1 ELSE 0 END)::numeric
        / NULLIF(COUNT(CASE WHEN fo.delivered_timestamp IS NOT NULL THEN 1 END), 0) * 100, 2
    ) AS late_delivery_pct,
    ROUND(AVG(fo.review_score), 2)                             AS avg_review_score,
    ROUND(AVG(fo.shipping_cost), 2)                            AS avg_shipping_cost
FROM fact_orders fo
JOIN dim_customer dc ON fo.customer_key = dc.customer_key
LEFT JOIN dim_geography dg ON dc.customer_zip_code = dg.zip_code_prefix
WHERE fo.order_status_raw = 'delivered'
GROUP BY dc.customer_state, dg.latitude, dg.longitude
ORDER BY total_revenue DESC;

CREATE OR REPLACE VIEW vw_monthly_trends AS
WITH monthly AS (
    SELECT
        dd.year,
        dd.month,
        dd.month_name,
        dd.quarter,
        MAKE_DATE(dd.year, dd.month, 1)                 AS month_date,
        COUNT(DISTINCT fo.order_id)                     AS orders,
        COUNT(DISTINCT dc.customer_unique_id)           AS customers,
        SUM(fo.price)                                    AS revenue,
        SUM(fo.shipping_cost)                           AS shipping,
        SUM(fo.total_order_value)                       AS total_value,
        ROUND(AVG(fo.review_score), 2)                  AS avg_review,
        SUM(CASE WHEN fo.is_late_delivery THEN 1 ELSE 0 END) AS late_count,
        COUNT(CASE WHEN fo.delivered_timestamp IS NOT NULL THEN 1 END) AS delivered_count
    FROM fact_orders fo
    JOIN dim_date dd ON fo.purchase_date_key = dd.date_key
    JOIN dim_customer dc ON fo.customer_key = dc.customer_key
    WHERE fo.order_status_raw = 'delivered'
    GROUP BY dd.year, dd.month, dd.month_name, dd.quarter
)
SELECT
    *,
    ROUND((1 - late_count::numeric / NULLIF(delivered_count, 0)) * 100, 2) AS otd_rate,
    LAG(revenue) OVER (ORDER BY year, month)              AS prev_month_revenue,
    LAG(orders)  OVER (ORDER BY year, month)              AS prev_month_orders,
    SUM(revenue) OVER (
        PARTITION BY year ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ytd_revenue,
    SUM(orders) OVER (
        PARTITION BY year ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ytd_orders
FROM monthly
ORDER BY year, month;