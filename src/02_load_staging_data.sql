USE olist_dw;

/*
导入说明：
1. MySQL Workbench 对包含中文的本地路径读取异常，因此导入时使用纯英文临时目录。
2. 执行前，将9个原始CSV复制到：
   C:/Users/Administrator/Desktop/workspace/load_tmp/
3. 原始CSV仍保留在项目data目录，load_tmp不上传GitHub。
4. 本脚本会先清空暂存表，请勿在生产数据库中使用。
*/

-- 1. 商品类别翻译表
TRUNCATE TABLE stg_category_translation;

LOAD DATA LOCAL INFILE
'C:/Users/Administrator/Desktop/workspace/load_tmp/product_category_name_translation.csv'
INTO TABLE stg_category_translation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    @category_name,
    @category_name_english
)
SET
    product_category_name = NULLIF(@category_name, ''),
    product_category_name_english =
        NULLIF(TRIM(TRAILING '\r' FROM @category_name_english), '');

-- 2. 客户表
TRUNCATE TABLE stg_customers;

LOAD DATA LOCAL INFILE
'C:/Users/Administrator/Desktop/workspace/load_tmp/olist_customers_dataset.csv'
INTO TABLE stg_customers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    @customer_state
)
SET customer_state =
    NULLIF(TRIM(TRAILING '\r' FROM @customer_state), '');

-- 3. 地理位置表
TRUNCATE TABLE stg_geolocation;

LOAD DATA LOCAL INFILE
'C:/Users/Administrator/Desktop/workspace/load_tmp/olist_geolocation_dataset.csv'
INTO TABLE stg_geolocation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    @geolocation_state
)
SET geolocation_state =
    NULLIF(TRIM(TRAILING '\r' FROM @geolocation_state), '');

-- 4. 订单主表
TRUNCATE TABLE stg_orders;

LOAD DATA LOCAL INFILE
'C:/Users/Administrator/Desktop/workspace/load_tmp/olist_orders_dataset.csv'
INTO TABLE stg_orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    @order_approved_at,
    @order_delivered_carrier_date,
    @order_delivered_customer_date,
    @order_estimated_delivery_date
)
SET
    order_approved_at = NULLIF(@order_approved_at, ''),
    order_delivered_carrier_date =
        NULLIF(@order_delivered_carrier_date, ''),
    order_delivered_customer_date =
        NULLIF(@order_delivered_customer_date, ''),
    order_estimated_delivery_date =
        NULLIF(
            TRIM(TRAILING '\r' FROM @order_estimated_delivery_date),
            ''
        );

-- 5. 订单商品明细表
TRUNCATE TABLE stg_order_items;

LOAD DATA LOCAL INFILE
'C:/Users/Administrator/Desktop/workspace/load_tmp/olist_order_items_dataset.csv'
INTO TABLE stg_order_items
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    @freight_value
)
SET freight_value =
    NULLIF(TRIM(TRAILING '\r' FROM @freight_value), '');
    -- 6. 支付表
TRUNCATE TABLE stg_order_payments;

LOAD DATA LOCAL INFILE
'C:/Users/Administrator/Desktop/workspace/load_tmp/olist_order_payments_dataset.csv'
INTO TABLE stg_order_payments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    @payment_value
)
SET payment_value =
    NULLIF(TRIM(TRAILING '\r' FROM @payment_value), '');

-- 7. 评价表
TRUNCATE TABLE stg_order_reviews;

LOAD DATA LOCAL INFILE
'C:/Users/Administrator/Desktop/workspace/load_tmp/olist_order_reviews_dataset.csv'
INTO TABLE stg_order_reviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    review_id,
    order_id,
    review_score,
    @review_comment_title,
    @review_comment_message,
    review_creation_date,
    @review_answer_timestamp
)
SET
    review_comment_title =
        NULLIF(@review_comment_title, ''),
    review_comment_message =
        NULLIF(@review_comment_message, ''),
    review_answer_timestamp =
        NULLIF(
            TRIM(TRAILING '\r' FROM @review_answer_timestamp),
            ''
        );

-- 8. 商品表
TRUNCATE TABLE stg_products;

LOAD DATA LOCAL INFILE
'C:/Users/Administrator/Desktop/workspace/load_tmp/olist_products_dataset.csv'
INTO TABLE stg_products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    product_id,
    @product_category_name,
    @product_name_length,
    @product_description_length,
    @product_photos_qty,
    @product_weight_g,
    @product_length_cm,
    @product_height_cm,
    @product_width_cm
)
SET
    product_category_name =
        NULLIF(@product_category_name, ''),
    product_name_length =
        NULLIF(@product_name_length, ''),
    product_description_length =
        NULLIF(@product_description_length, ''),
    product_photos_qty =
        NULLIF(@product_photos_qty, ''),
    product_weight_g =
        NULLIF(@product_weight_g, ''),
    product_length_cm =
        NULLIF(@product_length_cm, ''),
    product_height_cm =
        NULLIF(@product_height_cm, ''),
    product_width_cm =
        NULLIF(
            TRIM(TRAILING '\r' FROM @product_width_cm),
            ''
        );

-- 9. 卖家表
TRUNCATE TABLE stg_sellers;

LOAD DATA LOCAL INFILE
'C:/Users/Administrator/Desktop/workspace/load_tmp/olist_sellers_dataset.csv'
INTO TABLE stg_sellers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    @seller_state
)
SET seller_state =
    NULLIF(TRIM(TRAILING '\r' FROM @seller_state), '');

-- 10. 导入完成后的统一行数检查
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
