-- 1. RFM SEGMENTATION
-- Segments customers into actionable groups based on
-- Recency, Frequency, and Monetary value
CREATE OR REPLACE VIEW view_rfm_segmentation AS
WITH rfm_base AS (
    SELECT
        dc.customer_unique_id,
        dc.customer_city,
        dc.customer_state,
        MAX(fo.purchase_timestamp)                    AS last_purchase_date,
        COUNT(DISTINCT fo.order_id)                   AS frequency,
        SUM(fo.total_order_value)                     AS monetary,
        AVG(fo.total_order_value)                     AS avg_order_value,
        COUNT(DISTINCT dp.category_name_en)           AS distinct_categories
    FROM fact_orders fo
    JOIN dim_customer dc ON fo.customer_key = dc.customer_key
    JOIN dim_product dp ON fo.product_key = dp.product_key
    WHERE fo.order_status_raw = 'delivered'
    GROUP BY dc.customer_unique_id, dc.customer_city, dc.customer_state
),
rfm_scored AS (
    SELECT
        *,
        EXTRACT(DAY FROM ('2018-10-01'::timestamp - last_purchase_date)) AS recency_days,
        NTILE(5) OVER (ORDER BY EXTRACT(DAY FROM ('2018-10-01'::timestamp - last_purchase_date)) DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)              AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)               AS m_score
    FROM rfm_base
)
SELECT
    *,
    r_score * 100 + f_score * 10 + m_score              AS rfm_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3                  THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2                  THEN 'New Customers'
        WHEN r_score = 3  AND f_score >= 3                  THEN 'Potential Loyalists'
        WHEN r_score = 3  AND f_score <= 2                  THEN 'Promising'
        WHEN r_score = 2  AND f_score >= 3                  THEN 'At Risk'
        WHEN r_score = 2  AND f_score <= 2                  THEN 'About to Sleep'
        WHEN r_score = 1  AND f_score >= 3                  THEN 'Cannot Lose Them'
        WHEN r_score = 1  AND f_score <= 2                  THEN 'Hibernating'
        ELSE 'Others'
    END AS customer_segment
FROM rfm_scored;

-- 2. COHORT RETENTION ANALYSIS
-- Tracks how many customers from each monthly cohort
-- return to make purchases in subsequent months
CREATE OR REPLACE VIEW view_cohort_retention AS
WITH customer_first_purchase AS (
    SELECT
        dc.customer_unique_id,
        DATE_TRUNC('month', MIN(fo.purchase_timestamp))::date AS cohort_month
    FROM fact_orders fo
    JOIN dim_customer dc ON fo.customer_key = dc.customer_key
    WHERE fo.order_status_raw = 'delivered'
    GROUP BY dc.customer_unique_id
),
customer_activity AS (
    SELECT
        dc.customer_unique_id,
        DATE_TRUNC('month', fo.purchase_timestamp)::date AS activity_month
    FROM fact_orders fo
    JOIN dim_customer dc ON fo.customer_key = dc.customer_key
    WHERE fo.order_status_raw = 'delivered'
    GROUP BY dc.customer_unique_id, DATE_TRUNC('month', fo.purchase_timestamp)::date
),
cohort_data AS (
    SELECT
        cfp.cohort_month,
        ca.activity_month,
        (EXTRACT(YEAR FROM ca.activity_month) - EXTRACT(YEAR FROM cfp.cohort_month)) * 12
            + (EXTRACT(MONTH FROM ca.activity_month) - EXTRACT(MONTH FROM cfp.cohort_month)) AS month_number,
        COUNT(DISTINCT ca.customer_unique_id) AS active_customers
    FROM customer_first_purchase cfp
    JOIN customer_activity ca ON cfp.customer_unique_id = ca.customer_unique_id
    GROUP BY cfp.cohort_month, ca.activity_month
)
SELECT
    cohort_month,
    month_number,
    active_customers,
    FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY month_number) AS cohort_size,
    ROUND(
        active_customers::numeric /
        FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY month_number) * 100, 2
    ) AS retention_rate_pct
FROM cohort_data
WHERE month_number >= 0
ORDER BY cohort_month, month_number;

-- 3. CUSTOMER LIFETIME VALUE (CLV) ESTIMATION
-- Estimates future value of customers using historical patterns
-- Formula: CLV = Avg Order Value × Purchase Frequency × Avg Lifespan
CREATE OR REPLACE VIEW view_customer_ltv AS
WITH customer_metrics AS (
    SELECT
        dc.customer_unique_id,
        dc.customer_state,
        COUNT(DISTINCT fo.order_id)         AS total_orders,
        SUM(fo.total_order_value)           AS total_revenue,
        AVG(fo.total_order_value)           AS avg_order_value,
        MIN(fo.purchase_timestamp)          AS first_purchase,
        MAX(fo.purchase_timestamp)          AS last_purchase,
        EXTRACT(DAY FROM MAX(fo.purchase_timestamp) - MIN(fo.purchase_timestamp)) AS customer_lifespan_days
    FROM fact_orders fo
    JOIN dim_customer dc ON fo.customer_key = dc.customer_key
    WHERE fo.order_status_raw = 'delivered'
    GROUP BY dc.customer_unique_id, dc.customer_state
)
SELECT
    customer_unique_id,
    customer_state,
    total_orders,
    total_revenue,
    avg_order_value,
    first_purchase,
    last_purchase,
    customer_lifespan_days,
    CASE
        WHEN customer_lifespan_days > 0
        THEN ROUND(total_orders::numeric / (customer_lifespan_days / 365.25), 2)
        ELSE total_orders
    END AS purchase_frequency_annual,
    CASE
        WHEN customer_lifespan_days > 0
        THEN ROUND(avg_order_value * (total_orders::numeric / (customer_lifespan_days / 365.25)) * 2, 2)
        ELSE ROUND(avg_order_value * 1, 2)
    END AS estimated_clv_2yr,
    NTILE(5) OVER (ORDER BY total_revenue ASC) AS clv_tier
FROM customer_metrics;

-- 4. MARKET BASKET ANALYSIS
-- Finds products frequently purchased together
-- (Co-occurrence analysis by order for bundling strategy)
CREATE OR REPLACE VIEW view_market_basket AS
WITH order_products AS (
    SELECT DISTINCT
        fo.order_id,
        dp.category_name_en AS category
    FROM fact_orders fo
    JOIN dim_product dp ON fo.product_key = dp.product_key
    WHERE fo.order_status_raw = 'delivered'
      AND dp.category_name_en IS NOT NULL
)
SELECT
    a.category        AS product_a,
    b.category        AS product_b,
    COUNT(*)           AS co_occurrence_count,
    ROUND(
        COUNT(*)::numeric / (
            SELECT COUNT(DISTINCT order_id) FROM order_products
        ) * 100, 4
    ) AS support_pct
FROM order_products a
JOIN order_products b
    ON a.order_id = b.order_id
    AND a.category < b.category
GROUP BY a.category, b.category
HAVING COUNT(*) >= 10
ORDER BY co_occurrence_count DESC;

-- 5. PARETO ANALYSIS (80/20 Rule)
-- Identifies which ~20% of products generate ~80% of revenue
CREATE OR REPLACE VIEW view_pareto_analysis AS
WITH category_revenue AS (
    SELECT
        dp.category_name_en                AS category,
        COUNT(DISTINCT fo.order_id)        AS total_orders,
        SUM(fo.price)                       AS total_revenue,
        AVG(fo.review_score)               AS avg_review_score
    FROM fact_orders fo
    JOIN dim_product dp ON fo.product_key = dp.product_key
    WHERE fo.order_status_raw = 'delivered'
      AND dp.category_name_en IS NOT NULL
    GROUP BY dp.category_name_en
),
ranked AS (
    SELECT
        *,
        SUM(total_revenue) OVER ()                                              AS grand_total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC)                   AS cumulative_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC)                          AS rank_position,
        COUNT(*) OVER ()                                                         AS total_categories
    FROM category_revenue
)
SELECT
    *,
    ROUND(total_revenue / grand_total_revenue * 100, 2)       AS revenue_share_pct,
    ROUND(cumulative_revenue / grand_total_revenue * 100, 2)  AS cumulative_revenue_pct,
    ROUND(rank_position::numeric / total_categories * 100, 2) AS category_percentile,
    CASE
        WHEN cumulative_revenue / grand_total_revenue <= 0.80 THEN 'Star (Top 80%)'
        ELSE 'Long Tail'
    END AS pareto_classification
FROM ranked
ORDER BY rank_position;

-- 6. LOGISTICS PERFORMANCE
-- Analyzes delivery performance by region and identifies
-- late delivery patterns
CREATE OR REPLACE VIEW view_logistics_performance AS
WITH delivery_metrics AS (
    SELECT
        fo.order_id,
        dc.customer_state,
        dc.customer_city,
        fo.purchase_timestamp,
        fo.delivered_timestamp,
        fo.estimated_delivery_date,
        fo.delivery_days_actual,
        fo.delivery_days_estimated,
        fo.delivery_delay_days,
        fo.is_late_delivery,
        fo.shipping_cost,
        fo.price,
        fo.review_score
    FROM fact_orders fo
    JOIN dim_customer dc ON fo.customer_key = dc.customer_key
    WHERE fo.order_status_raw = 'delivered'
      AND fo.delivered_timestamp IS NOT NULL
)
SELECT
    customer_state,
    COUNT(*)                                                            AS total_deliveries,
    ROUND(AVG(delivery_days_actual), 1)                                 AS avg_delivery_days,
    ROUND(AVG(delivery_days_estimated), 1)                              AS avg_estimated_days,
    SUM(CASE WHEN is_late_delivery THEN 1 ELSE 0 END)                  AS late_deliveries,
    ROUND(SUM(CASE WHEN is_late_delivery THEN 1 ELSE 0 END)::numeric
          / COUNT(*) * 100, 2)                                         AS late_delivery_pct,
    ROUND(AVG(CASE WHEN is_late_delivery THEN delivery_delay_days END), 1) AS avg_delay_days_when_late,
    ROUND(AVG(shipping_cost), 2)                                        AS avg_shipping_cost,
    ROUND(AVG(shipping_cost / NULLIF(price, 0) * 100), 2)             AS shipping_cost_ratio_pct,
    ROUND(AVG(review_score), 2)                                         AS avg_review_score
FROM delivery_metrics
GROUP BY customer_state
ORDER BY late_delivery_pct DESC;

-- 7. SELLER SCORECARD
-- Composite performance score for each seller combining
-- revenue, review ratings, and delivery performance
CREATE OR REPLACE VIEW view_seller_scorecard AS
WITH seller_metrics AS (
    SELECT
        ds.seller_id,
        ds.seller_city,
        ds.seller_state,
        COUNT(DISTINCT fo.order_id)                     AS total_orders,
        COUNT(DISTINCT dc.customer_unique_id)           AS unique_customers,
        SUM(fo.total_order_value)                       AS total_revenue,
        AVG(fo.total_order_value)                       AS avg_order_value,
        ROUND(AVG(fo.review_score), 2)                  AS avg_review_score,
        SUM(CASE WHEN fo.is_late_delivery THEN 1 ELSE 0 END) AS late_deliveries,
        ROUND(AVG(fo.delivery_days_actual), 1)          AS avg_delivery_days,
        COUNT(DISTINCT dp.category_name_en)             AS categories_sold
    FROM fact_orders fo
    JOIN dim_seller ds ON fo.seller_key = ds.seller_key
    JOIN dim_customer dc ON fo.customer_key = dc.customer_key
    JOIN dim_product dp ON fo.product_key = dp.product_key
    WHERE fo.order_status_raw = 'delivered'
    GROUP BY ds.seller_id, ds.seller_city, ds.seller_state
),
scored AS (
    SELECT
        *,
        ROUND(
            (1 - late_deliveries::numeric / NULLIF(total_orders, 0)) * 100, 2
        ) AS on_time_delivery_pct,
        NTILE(5) OVER (ORDER BY total_revenue ASC)         AS revenue_score,
        NTILE(5) OVER (ORDER BY avg_review_score ASC)      AS review_score_rank,
        NTILE(5) OVER (ORDER BY (1 - late_deliveries::numeric / NULLIF(total_orders, 0)) ASC) AS otd_score
    FROM seller_metrics
    WHERE total_orders >= 5
)
SELECT
    *,
    ROUND((revenue_score * 0.4 + review_score_rank * 0.3 + otd_score * 0.3), 2) AS composite_score,
    CASE
        WHEN (revenue_score * 0.4 + review_score_rank * 0.3 + otd_score * 0.3) >= 4.0 THEN 'Gold'
        WHEN (revenue_score * 0.4 + review_score_rank * 0.3 + otd_score * 0.3) >= 3.0 THEN 'Silver'
        WHEN (revenue_score * 0.4 + review_score_rank * 0.3 + otd_score * 0.3) >= 2.0 THEN 'Bronze'
        ELSE 'Needs Improvement'
    END AS seller_tier
FROM scored
ORDER BY composite_score DESC;

-- 8. REVENUE TRENDS (MoM / YoY)
-- Time-series analysis with Month-over-Month and
-- Year-over-Year growth using window functions
CREATE OR REPLACE VIEW view_revenue_trends AS
WITH monthly_revenue AS (
    SELECT
        dd.year,
        dd.quarter,
        dd.month,
        dd.month_name,
        COUNT(DISTINCT fo.order_id)        AS total_orders,
        COUNT(DISTINCT dc.customer_unique_id) AS unique_customers,
        SUM(fo.price)                       AS gross_revenue,
        SUM(fo.shipping_cost)              AS total_shipping_cost,
        SUM(fo.total_order_value)          AS total_revenue,
        ROUND(AVG(fo.total_order_value), 2) AS avg_order_value,
        ROUND(AVG(fo.review_score), 2)     AS avg_review_score
    FROM fact_orders fo
    JOIN dim_date dd ON fo.purchase_date_key = dd.date_key
    JOIN dim_customer dc ON fo.customer_key = dc.customer_key
    WHERE fo.order_status_raw = 'delivered'
    GROUP BY dd.year, dd.quarter, dd.month, dd.month_name
)
SELECT
    *,
    LAG(total_revenue) OVER (ORDER BY year, month)       AS prev_month_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY year, month))
        / NULLIF(LAG(total_revenue) OVER (ORDER BY year, month), 0) * 100, 2
    ) AS mom_growth_pct,
    LAG(total_revenue, 12) OVER (ORDER BY year, month)   AS same_month_prev_year_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue, 12) OVER (ORDER BY year, month))
        / NULLIF(LAG(total_revenue, 12) OVER (ORDER BY year, month), 0) * 100, 2
    ) AS yoy_growth_pct,
    SUM(total_revenue) OVER (
        PARTITION BY year ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ytd_revenue
FROM monthly_revenue
ORDER BY year, month;

-- 9. PAYMENT ANALYSIS
-- Analyzes payment behavior, method preferences, and
-- installment patterns
CREATE OR REPLACE VIEW view_payment_analysis AS
WITH payment_metrics AS (
    SELECT
        dpt.payment_type,
        dd.year,
        dd.month,
        COUNT(*)                                        AS transaction_count,
        SUM(fp.payment_value)                           AS total_payment_value,
        AVG(fp.payment_value)                           AS avg_payment_value,
        AVG(fp.payment_installments)                    AS avg_installments,
        MAX(fp.payment_installments)                    AS max_installments,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fp.payment_value) AS median_payment_value
    FROM fact_payments fp
    JOIN dim_payment_type dpt ON fp.payment_type_key = dpt.payment_type_key
    JOIN dim_date dd ON fp.purchase_date_key = dd.date_key
    GROUP BY dpt.payment_type, dd.year, dd.month
)
SELECT
    *,
    ROUND(total_payment_value / NULLIF(SUM(total_payment_value) OVER (
        PARTITION BY year, month
    ), 0) * 100, 2) AS payment_share_pct
FROM payment_metrics
ORDER BY year, month, total_payment_value DESC;

-- 10. CATEGORY PERFORMANCE MATRIX (BCG-Style)
-- Classifies product categories using Revenue (market share)
-- and Growth Rate into Stars, Cash Cows, Question Marks, Dogs
CREATE OR REPLACE VIEW view_category_performance AS
WITH category_monthly AS (
    SELECT
        dp.category_name_en                             AS category,
        dd.year,
        dd.quarter,
        SUM(fo.price)                                    AS revenue,
        COUNT(DISTINCT fo.order_id)                     AS order_count,
        ROUND(AVG(fo.review_score), 2)                  AS avg_review
    FROM fact_orders fo
    JOIN dim_product dp ON fo.product_key = dp.product_key
    JOIN dim_date dd ON fo.purchase_date_key = dd.date_key
    WHERE fo.order_status_raw = 'delivered'
      AND dp.category_name_en IS NOT NULL
    GROUP BY dp.category_name_en, dd.year, dd.quarter
),
category_summary AS (
    SELECT
        category,
        SUM(revenue)                                        AS total_revenue,
        SUM(order_count)                                    AS total_orders,
        AVG(avg_review)                                     AS avg_review_score,
        MAX(CASE WHEN year = 2018 AND quarter = 3 THEN revenue ELSE 0 END) AS recent_quarter_rev,
        MAX(CASE WHEN year = 2018 AND quarter = 2 THEN revenue ELSE 0 END) AS prev_quarter_rev
    FROM category_monthly
    GROUP BY category
),
classified AS (
    SELECT
        *,
        ROUND(total_revenue / NULLIF(SUM(total_revenue) OVER (), 0) * 100, 2) AS market_share_pct,
        CASE
            WHEN prev_quarter_rev > 0
            THEN ROUND((recent_quarter_rev - prev_quarter_rev)::numeric / prev_quarter_rev * 100, 2)
            ELSE NULL
        END AS growth_rate_pct,
        NTILE(2) OVER (ORDER BY total_revenue ASC) AS revenue_rank,
        NTILE(2) OVER (ORDER BY
            CASE WHEN prev_quarter_rev > 0
                 THEN (recent_quarter_rev - prev_quarter_rev)::numeric / prev_quarter_rev
                 ELSE 0 END ASC
        ) AS growth_rank
    FROM category_summary
)
SELECT
    *,
    CASE
        WHEN revenue_rank = 2 AND growth_rank = 2 THEN 'Star'
        WHEN revenue_rank = 2 AND growth_rank = 1 THEN 'Cash Cow'
        WHEN revenue_rank = 1 AND growth_rank = 2 THEN 'Question Mark'
        WHEN revenue_rank = 1 AND growth_rank = 1 THEN 'Dog'
        ELSE 'Unclassified'
    END AS bcg_classification
FROM classified
ORDER BY total_revenue DESC;