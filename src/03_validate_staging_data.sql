USE olist_dw;

-- 1. 统一检查9张暂存表的行数
SELECT 'stg_category_translation' AS table_name, COUNT(*) AS row_count
FROM stg_category_translation
UNION ALL
SELECT 'stg_customers', COUNT(*) FROM stg_customers
UNION ALL
SELECT 'stg_geolocation', COUNT(*) FROM stg_geolocation
UNION ALL
SELECT 'stg_order_items', COUNT(*) FROM stg_order_items
UNION ALL
SELECT 'stg_order_payments', COUNT(*) FROM stg_order_payments
UNION ALL
SELECT 'stg_order_reviews', COUNT(*) FROM stg_order_reviews
UNION ALL
SELECT 'stg_orders', COUNT(*) FROM stg_orders
UNION ALL
SELECT 'stg_products', COUNT(*) FROM stg_products
UNION ALL
SELECT 'stg_sellers', COUNT(*) FROM stg_sellers;

-- 2. 检查订单状态分布
SELECT
    order_status,
    COUNT(*) AS order_count
FROM stg_orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 3. 检查评价分数分布
SELECT
    review_score,
    COUNT(*) AS review_count
FROM stg_order_reviews
GROUP BY review_score
ORDER BY review_score;

-- 4. 检查订单主表与客户表的关联完整性
SELECT
    COUNT(*) AS unmatched_customer_orders
FROM stg_orders o
LEFT JOIN stg_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 5. 检查订单明细中的商品和卖家是否缺失
SELECT
    SUM(p.product_id IS NULL) AS unmatched_product_items,
    SUM(s.seller_id IS NULL) AS unmatched_seller_items
FROM stg_order_items oi
LEFT JOIN stg_products p
    ON oi.product_id = p.product_id
LEFT JOIN stg_sellers s
    ON oi.seller_id = s.seller_id;
