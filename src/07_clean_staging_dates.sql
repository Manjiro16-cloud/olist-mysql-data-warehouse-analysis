USE olist_dw;

SET SQL_SAFE_UPDATES = 0;

UPDATE stg_orders
SET order_approved_at = NULL
WHERE CAST(order_approved_at AS CHAR) LIKE '0000-00-00%';

UPDATE stg_orders
SET order_delivered_carrier_date = NULL
WHERE CAST(order_delivered_carrier_date AS CHAR) LIKE '0000-00-00%';

UPDATE stg_orders
SET order_delivered_customer_date = NULL
WHERE CAST(order_delivered_customer_date AS CHAR) LIKE '0000-00-00%';

SET SQL_SAFE_UPDATES = 1;

SELECT
    SUM(order_approved_at IS NULL) AS null_approved_at,
    SUM(order_delivered_carrier_date IS NULL) AS null_carrier_date,
    SUM(order_delivered_customer_date IS NULL) AS null_customer_delivery,
    SUM(order_estimated_delivery_date IS NULL) AS null_estimated_delivery
FROM stg_orders;
