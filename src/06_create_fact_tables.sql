USE olist_dw;

-- 1. 订单级事实表
CREATE TABLE IF NOT EXISTS fact_orders (
    order_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id CHAR(32) NOT NULL UNIQUE,
    customer_key INT NOT NULL,
    purchase_date_key INT NOT NULL,
    order_status VARCHAR(30) NOT NULL,

    order_purchase_timestamp DATETIME NOT NULL,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,

    item_count INT NOT NULL DEFAULT 0,
    product_value DECIMAL(14, 2) NOT NULL DEFAULT 0,
    freight_value DECIMAL(14, 2) NOT NULL DEFAULT 0,
    payment_value DECIMAL(14, 2) NOT NULL DEFAULT 0,
    average_review_score DECIMAL(4, 2),

    delivery_days INT,
    delivery_delay_days INT,
    delivered_on_time TINYINT(1),

    CONSTRAINT fk_fact_orders_customer
        FOREIGN KEY (customer_key)
        REFERENCES dim_customer(customer_key),

    CONSTRAINT fk_fact_orders_date
        FOREIGN KEY (purchase_date_key)
        REFERENCES dim_date(date_key),

    INDEX idx_fact_orders_status (order_status),
    INDEX idx_fact_orders_purchase_date (purchase_date_key),
    INDEX idx_fact_orders_customer (customer_key)
);

-- 2. 订单商品明细事实表
CREATE TABLE IF NOT EXISTS fact_order_items (
    order_item_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id CHAR(32) NOT NULL,
    order_item_id INT NOT NULL,
    purchase_date_key INT NOT NULL,
    customer_key INT NOT NULL,
    product_key INT NOT NULL,
    seller_key INT NOT NULL,

    shipping_limit_date DATETIME,
    item_price DECIMAL(12, 2) NOT NULL,
    freight_value DECIMAL(12, 2) NOT NULL,
    total_item_value DECIMAL(12, 2) NOT NULL,

    CONSTRAINT uq_fact_order_item
        UNIQUE (order_id, order_item_id),

    CONSTRAINT fk_fact_items_order
        FOREIGN KEY (order_id)
        REFERENCES fact_orders(order_id),

    CONSTRAINT fk_fact_items_date
        FOREIGN KEY (purchase_date_key)
        REFERENCES dim_date(date_key),

    CONSTRAINT fk_fact_items_customer
        FOREIGN KEY (customer_key)
        REFERENCES dim_customer(customer_key),

    CONSTRAINT fk_fact_items_product
        FOREIGN KEY (product_key)
        REFERENCES dim_product(product_key),

    CONSTRAINT fk_fact_items_seller
        FOREIGN KEY (seller_key)
        REFERENCES dim_seller(seller_key),

    INDEX idx_fact_items_date (purchase_date_key),
    INDEX idx_fact_items_product (product_key),
    INDEX idx_fact_items_seller (seller_key),
    INDEX idx_fact_items_customer (customer_key)
);

SHOW TABLES LIKE 'fact_%';
