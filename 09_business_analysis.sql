USE olist_dw;

-- 分析1：月度经营趋势与环比增长
WITH monthly_metrics AS (
    SELECT
        d.year_month_label,
        COUNT(DISTINCT fo.order_id) AS order_count,
        COUNT(DISTINCT c.customer_unique_id) AS customer_count,
        ROUND(SUM(fo.product_value), 2) AS product_gmv,
        ROUND(SUM(fo.freight_value), 2) AS freight_revenue,
        ROUND(AVG(fo.product_value), 2) AS avg_order_product_value
    FROM fact_orders fo
    JOIN dim_date d
        ON fo.purchase_date_key = d.date_key
    JOIN dim_customer c
        ON fo.customer_key = c.customer_key
    WHERE fo.order_status NOT IN ('canceled', 'unavailable')
      AND fo.product_value > 0
    GROUP BY d.year_month_label
),
monthly_comparison AS (
    SELECT
        *,
        LAG(product_gmv) OVER (
            ORDER BY year_month_label
        ) AS previous_month_gmv
    FROM monthly_metrics
)
SELECT
    year_month_label,
    order_count,
    customer_count,
    product_gmv,
    freight_revenue,
    avg_order_product_value,
    ROUND(
        100 * (product_gmv - previous_month_gmv)
        / NULLIF(previous_month_gmv, 0),
        2
    ) AS gmv_month_over_month_pct,
    DENSE_RANK() OVER (
        ORDER BY product_gmv DESC
    ) AS gmv_rank
FROM monthly_comparison
ORDER BY year_month_label;
-- 分析2：商品品类销售排名与贡献
WITH category_metrics AS (
    SELECT
        COALESCE(p.category_name_english, 'unknown') AS category_name,
        COUNT(DISTINCT fi.order_id) AS order_count,
        COUNT(*) AS item_count,
        ROUND(SUM(fi.item_price), 2) AS product_gmv,
        ROUND(SUM(fi.freight_value), 2) AS freight_revenue,
        ROUND(AVG(fi.item_price), 2) AS avg_item_price
    FROM fact_order_items fi
    JOIN fact_orders fo
        ON fi.order_id = fo.order_id
    JOIN dim_product p
        ON fi.product_key = p.product_key
    WHERE fo.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY COALESCE(p.category_name_english, 'unknown')
),
category_with_share AS (
    SELECT
        *,
        ROUND(
            100 * product_gmv
            / NULLIF(SUM(product_gmv) OVER (), 0),
            2
        ) AS gmv_share_pct
    FROM category_metrics
)
SELECT
    category_name,
    order_count,
    item_count,
    product_gmv,
    freight_revenue,
    avg_item_price,
    gmv_share_pct,
    DENSE_RANK() OVER (
        ORDER BY product_gmv DESC
    ) AS gmv_rank
FROM category_with_share
WHERE category_name <> 'unknown'
ORDER BY product_gmv DESC
LIMIT 15;
-- 分析3：客户RFM分层
WITH customer_metrics AS (
    SELECT
        c.customer_unique_id,
        MAX(DATE(fo.order_purchase_timestamp)) AS last_purchase_date,
        COUNT(DISTINCT fo.order_id) AS order_frequency,
        ROUND(SUM(fo.product_value), 2) AS monetary_value
    FROM fact_orders fo
    JOIN dim_customer c
        ON fo.customer_key = c.customer_key
    WHERE fo.order_status NOT IN ('canceled', 'unavailable')
      AND fo.product_value > 0
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT
        *,
        DATEDIFF(
            (SELECT MAX(full_date) FROM dim_date),
            last_purchase_date
        ) AS recency_days,
        NTILE(4) OVER (
            ORDER BY DATEDIFF(
                (SELECT MAX(full_date) FROM dim_date),
                last_purchase_date
            ) DESC
        ) AS recency_score,
        NTILE(4) OVER (
            ORDER BY order_frequency
        ) AS frequency_score,
        NTILE(4) OVER (
            ORDER BY monetary_value
        ) AS monetary_score
    FROM customer_metrics
),
rfm_segments AS (
    SELECT
        *,
        CASE
            WHEN recency_score >= 3
                 AND frequency_score >= 3
                 AND monetary_score >= 3
                THEN '高价值客户'
            WHEN recency_score >= 3
                 AND frequency_score >= 2
                THEN '潜力客户'
            WHEN recency_score <= 2
                 AND frequency_score >= 2
                THEN '沉睡风险客户'
            ELSE '普通客户'
        END AS customer_segment
    FROM rfm_scores
)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(recency_days), 2) AS avg_recency_days,
    ROUND(AVG(order_frequency), 2) AS avg_order_frequency,
    ROUND(AVG(monetary_value), 2) AS avg_monetary_value,
    ROUND(
        100 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct
FROM rfm_segments
GROUP BY customer_segment
ORDER BY customer_count DESC;
-- 分析4：州级履约质量与评价表现
WITH state_metrics AS (
    SELECT
        c.customer_state,
        COUNT(*) AS delivered_order_count,
        ROUND(AVG(fo.delivery_days), 2) AS avg_delivery_days,
        ROUND(AVG(fo.delivery_delay_days), 2) AS avg_delivery_vs_estimated_days,
        ROUND(
            100 * SUM(fo.delivered_on_time = 1)
            / NULLIF(SUM(fo.delivered_on_time IS NOT NULL), 0),
            2
        ) AS on_time_rate_pct,
        ROUND(AVG(fo.average_review_score), 2) AS avg_review_score
    FROM fact_orders fo
    JOIN dim_customer c
        ON fo.customer_key = c.customer_key
    WHERE fo.delivered_on_time IS NOT NULL
    GROUP BY c.customer_state
)
SELECT
    customer_state,
    delivered_order_count,
    avg_delivery_days,
    avg_delivery_vs_estimated_days,
    on_time_rate_pct,
    avg_review_score,
    DENSE_RANK() OVER (
        ORDER BY on_time_rate_pct DESC
    ) AS on_time_rank
FROM state_metrics
WHERE delivered_order_count >= 100
ORDER BY on_time_rate_pct DESC;
-- 分析5：州级延迟率与延迟订单平均延迟天数
WITH state_delivery AS (
    SELECT
        c.customer_state,
        COUNT(*) AS delivered_order_count,

        SUM(fo.delivered_on_time = 0) AS late_order_count,

        ROUND(
            100 * SUM(fo.delivered_on_time = 0)
            / NULLIF(COUNT(*), 0),
            2
        ) AS late_rate_pct,

        ROUND(
            AVG(
                CASE
                    WHEN fo.delivery_delay_days > 0
                    THEN fo.delivery_delay_days
                END
            ),
            2
        ) AS avg_late_days,

        ROUND(AVG(fo.average_review_score), 2) AS avg_review_score
    FROM fact_orders fo
    JOIN dim_customer c
        ON fo.customer_key = c.customer_key
    WHERE fo.delivered_on_time IS NOT NULL
    GROUP BY c.customer_state
)
SELECT
    customer_state,
    delivered_order_count,
    late_order_count,
    late_rate_pct,
    avg_late_days,
    avg_review_score,
    DENSE_RANK() OVER (
        ORDER BY late_rate_pct DESC
    ) AS late_rate_rank
FROM state_delivery
WHERE delivered_order_count >= 100
ORDER BY late_rate_pct DESC;