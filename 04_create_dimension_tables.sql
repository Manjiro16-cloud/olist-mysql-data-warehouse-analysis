USE olist_dw;

-- 1. 日期维度
CREATE TABLE IF NOT EXISTS dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year_number SMALLINT NOT NULL,
    quarter_number TINYINT NOT NULL,
    month_number TINYINT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    year_month_label CHAR(7) NOT NULL,
    week_number TINYINT NOT NULL,
    day_of_month TINYINT NOT NULL,
    day_of_week_number TINYINT NOT NULL,
    day_of_week_name VARCHAR(15) NOT NULL,
    is_weekend TINYINT(1) NOT NULL
);

-- 2. 地理位置维度
CREATE TABLE IF NOT EXISTS dim_geography (
    geography_key INT AUTO_INCREMENT PRIMARY KEY,
    zip_code_prefix INT NOT NULL UNIQUE,
    city VARCHAR(100),
    state CHAR(2),
    average_latitude DECIMAL(10, 7),
    average_longitude DECIMAL(10, 7)
);

-- 3. 客户维度
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id CHAR(32) NOT NULL UNIQUE,
    customer_unique_id CHAR(32) NOT NULL,
    zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2),
    INDEX idx_customer_unique_id (customer_unique_id),
    INDEX idx_customer_location (customer_state, customer_city)
);

-- 4. 商品维度
CREATE TABLE IF NOT EXISTS dim_product (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    product_id CHAR(32) NOT NULL UNIQUE,
    category_name_portuguese VARCHAR(100),
    category_name_english VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT,
    INDEX idx_product_category (category_name_english)
);

-- 5. 卖家维度
CREATE TABLE IF NOT EXISTS dim_seller (
    seller_key INT AUTO_INCREMENT PRIMARY KEY,
    seller_id CHAR(32) NOT NULL UNIQUE,
    zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2),
    INDEX idx_seller_location (seller_state, seller_city)
);

SHOW TABLES LIKE 'dim_%';