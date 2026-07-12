USE olist_dw;

-- 按外键依赖顺序清空事实表
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE fact_order_items;
TRUNCATE TABLE fact_orders;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. 加载订单级事实表
INSERT INTO fact_orders (
    order_id,
    customer_key,
    purchase_date_key,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    item_count,
    product_value,
    freight_value,
    payment_value,
    average_review_score,
    delivery_days,
    delivery_delay_days,
    delivered_on_time
)
SELECT
    o.order_id,
    c.customer_key,
    d.date_key,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    COALESCE(i.item_count, 0),
    COALESCE(i.product_value, 0),
    COALESCE(i.freight_value, 0),
    COALESCE(p.payment_value, 0),
    ROUND(r.average_review_score, 2),

    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        ELSE DATEDIFF(
            o.order_delivered_customer_date,
            o.order_purchase_timestamp
        )
    END AS delivery_days,

    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        ELSE DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        )
    END AS delivery_delay_days,

    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date THEN 1
        ELSE 0
    END AS delivered_on_time

FROM stg_orders o
JOIN dim_customer c
    ON o.customer_id = c.customer_id
JOIN dim_date d
    ON DATE(o.order_purchase_timestamp) = d.full_date

LEFT JOIN (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS product_value,
        SUM(freight_value) AS freight_value
    FROM stg_order_items
    GROUP BY order_id
) i
    ON o.order_id = i.order_id

LEFT JOIN (
    SELECT
        order_id,
        SUM(payment_value) AS payment_value
    FROM stg_order_payments
    GROUP BY order_id
) p
    ON o.order_id = p.order_id

LEFT JOIN (
    SELECT
        order_id,
        AVG(review_score) AS average_review_score
    FROM stg_order_reviews
    GROUP BY order_id
) r
    ON o.order_id = r.order_id;

-- 2. 加载订单商品明细事实表
INSERT INTO fact_order_items (
    order_id,
    order_item_id,
    purchase_date_key,
    customer_key,
    product_key,
    seller_key,
    shipping_limit_date,
    item_price,
    freight_value,
    total_item_value
)
SELECT
    oi.order_id,
    oi.order_item_id,
    fo.purchase_date_key,
    fo.customer_key,
    p.product_key,
    s.seller_key,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value
FROM stg_order_items oi
JOIN fact_orders fo
    ON oi.order_id = fo.order_id
JOIN dim_product p
    ON oi.product_id = p.product_id
JOIN dim_seller s
    ON oi.seller_id = s.seller_id;

-- 3. 验证事实表行数
SELECT
    (SELECT COUNT(*) FROM fact_orders) AS fact_order_rows,
    (SELECT COUNT(*) FROM fact_order_items) AS fact_item_rows;

-- 4. 检查关键指标
SELECT
    COUNT(*) AS total_orders,
    SUM(item_count) AS total_items,
    ROUND(SUM(product_value), 2) AS total_product_value,
    ROUND(SUM(freight_value), 2) AS total_freight_value,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(average_review_score), 2) AS avg_review_score,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days
FROM fact_orders;