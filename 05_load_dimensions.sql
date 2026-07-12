USE olist_dw;

-- 允许日期递归超过1000天
SET SESSION cte_max_recursion_depth = 2000;

-- 清空维度表，保证脚本可以重新运行
TRUNCATE TABLE dim_date;
TRUNCATE TABLE dim_geography;
TRUNCATE TABLE dim_customer;
TRUNCATE TABLE dim_product;
TRUNCATE TABLE dim_seller;

-- 1. 加载日期维度
INSERT INTO dim_date (
    date_key,
    full_date,
    year_number,
    quarter_number,
    month_number,
    month_name,
    year_month_label,
    week_number,
    day_of_month,
    day_of_week_number,
    day_of_week_name,
    is_weekend
)
WITH RECURSIVE date_series AS (
    SELECT DATE(MIN(order_purchase_timestamp)) AS full_date
    FROM stg_orders

    UNION ALL

    SELECT DATE_ADD(full_date, INTERVAL 1 DAY)
    FROM date_series
    WHERE full_date < (
        SELECT DATE(MAX(order_estimated_delivery_date))
        FROM stg_orders
    )
)
SELECT
    CAST(DATE_FORMAT(full_date, '%Y%m%d') AS UNSIGNED) AS date_key,
    full_date,
    YEAR(full_date) AS year_number,
    QUARTER(full_date) AS quarter_number,
    MONTH(full_date) AS month_number,
    MONTHNAME(full_date) AS month_name,
    DATE_FORMAT(full_date, '%Y-%m') AS year_month_label,
    WEEKOFYEAR(full_date) AS week_number,
    DAY(full_date) AS day_of_month,
    DAYOFWEEK(full_date) AS day_of_week_number,
    DAYNAME(full_date) AS day_of_week_name,
    CASE
        WHEN DAYOFWEEK(full_date) IN (1, 7) THEN 1
        ELSE 0
    END AS is_weekend
FROM date_series;

-- 2. 加载地理位置维度
INSERT INTO dim_geography (
    zip_code_prefix,
    city,
    state,
    average_latitude,
    average_longitude
)
SELECT
    geolocation_zip_code_prefix,
    MIN(geolocation_city) AS city,
    MIN(geolocation_state) AS state,
    AVG(geolocation_lat) AS average_latitude,
    AVG(geolocation_lng) AS average_longitude
FROM stg_geolocation
GROUP BY geolocation_zip_code_prefix;

-- 3. 加载客户维度
INSERT INTO dim_customer (
    customer_id,
    customer_unique_id,
    zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM stg_customers;

-- 4. 加载商品维度，并补充英文类别
INSERT INTO dim_product (
    product_id,
    category_name_portuguese,
    category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    p.product_id,
    p.product_category_name,
    COALESCE(t.product_category_name_english, 'unknown') AS category_name_english,
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM stg_products p
LEFT JOIN stg_category_translation t
    ON p.product_category_name = t.product_category_name;

-- 5. 加载卖家维度
INSERT INTO dim_seller (
    seller_id,
    zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM stg_sellers;

-- 6. 验证各维度表行数
SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM dim_date
UNION ALL
SELECT 'dim_geography', COUNT(*) FROM dim_geography
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_seller', COUNT(*) FROM dim_seller;