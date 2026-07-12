USE olist_dw;

-- 1. 月度经营指标视图
CREATE OR REPLACE VIEW vw_monthly_business_metrics AS
SELECT
    d.year_month_label,
    COUNT(DISTINCT fo.order_id) AS order_count,
    COUNT(DISTINCT c.customer_unique_id) AS customer_count,
    ROUND(SUM(fo.product_value), 2) AS product_gmv,
    ROUND(SUM(fo.freight_value), 2) AS freight_value,
    ROUND(SUM(fo.payment_value), 2) AS payment_value,
    ROUND(AVG(fo.product_value), 2) AS avg_order_product_value
FROM fact_orders fo
JOIN dim_date d
    ON fo.purchase_date_key = d.date_key
JOIN dim_customer c
    ON fo.customer_key = c.customer_key
WHERE fo.order_status NOT IN ('canceled', 'unavailable')
  AND fo.product_value > 0
GROUP BY d.year_month_label;

-- 2. 品类经营指标视图
CREATE OR REPLACE VIEW vw_category_performance AS
SELECT
    COALESCE(p.category_name_english, 'unknown') AS category_name,
    COUNT(DISTINCT fi.order_id) AS order_count,
    COUNT(*) AS item_count,
    ROUND(SUM(fi.item_price), 2) AS product_gmv,
    ROUND(SUM(fi.freight_value), 2) AS freight_value,
    ROUND(AVG(fi.item_price), 2) AS avg_item_price
FROM fact_order_items fi
JOIN fact_orders fo
    ON fi.order_id = fo.order_id
JOIN dim_product p
    ON fi.product_key = p.product_key
WHERE fo.order_status NOT IN ('canceled', 'unavailable')
GROUP BY COALESCE(p.category_name_english, 'unknown');

-- 3. 地区履约质量视图
CREATE OR REPLACE VIEW vw_state_delivery_quality AS
SELECT
    c.customer_state,
    COUNT(*) AS delivered_order_count,
    SUM(fo.delivered_on_time = 0) AS late_order_count,
    ROUND(
        100 * SUM(fo.delivered_on_time = 0) / COUNT(*),
        2
    ) AS late_rate_pct,
    ROUND(AVG(fo.delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(fo.average_review_score), 2) AS avg_review_score
FROM fact_orders fo
JOIN dim_customer c
    ON fo.customer_key = c.customer_key
WHERE fo.delivered_on_time IS NOT NULL
GROUP BY c.customer_state;

SHOW FULL TABLES
WHERE Table_type = 'VIEW';
