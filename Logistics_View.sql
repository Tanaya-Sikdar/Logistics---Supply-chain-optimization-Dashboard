
--Check data volume

SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;

--Check nulls

SELECT 
    COUNT(*) AS total_orders,
    COUNT(order_delivered_customer_date) AS delivered_orders
FROM orders;

--Inspect timestamps

SELECT TOP 10 
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders;

--Create a dedicated schema

CREATE SCHEMA Analytics;
GO

--Create the view inside that schema

CREATE VIEW Analytics.vw_logistics_master AS
WITH order_level AS (
    SELECT
        oi.order_id,
        SUM(oi.freight_value) AS total_freight,
        SUM(oi.price) AS total_order_value,
        COUNT(DISTINCT oi.seller_id) AS seller_count
    FROM order_items oi
    GROUP BY oi.order_id
),
seller_location AS (
    SELECT 
        oi.order_id,
        MIN(s.seller_state) AS seller_state -- controlled fallback
    FROM order_items oi
    JOIN sellers s 
        ON oi.seller_id = s.seller_id
    GROUP BY oi.order_id
)
SELECT
    o.order_id,
    o.customer_id,
    c.customer_state,
    sl.seller_state,

    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS actual_delivery_days,
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_estimated_delivery_date) AS estimated_delivery_days,
    DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) AS delay_days,

    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1
        ELSE 0
    END AS is_on_time,

    ol.total_freight,
    ol.total_order_value,
    ol.seller_count,

    AVG(CAST(r.review_score AS FLOAT)) AS avg_review_score

FROM orders o
JOIN order_level ol ON o.order_id = ol.order_id
JOIN seller_location sl ON o.order_id = sl.order_id
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL

GROUP BY
    o.order_id,
    o.customer_id,
    c.customer_state,
    sl.seller_state,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    ol.total_freight,
    ol.total_order_value,
    ol.seller_count;

    --Data Validation & Sanity Checks

    SELECT COUNT(*) FROM Analytics.vw_logistics_master;

    SELECT COUNT(DISTINCT order_id) FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

  --Create Product Dimension
  CREATE OR ALTER VIEW Analytics.vw_dim_products AS
SELECT 
    p.product_id,

    COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') 
        AS product_category,

    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,

    CASE 
        WHEN p.product_length_cm IS NOT NULL 
         AND p.product_height_cm IS NOT NULL 
         AND p.product_width_cm IS NOT NULL
        THEN 
            CAST(p.product_length_cm AS FLOAT) *
            CAST(p.product_height_cm AS FLOAT) *
            CAST(p.product_width_cm AS FLOAT)
        ELSE NULL
    END AS product_volume_cm3

FROM products p
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name;

    --Create Customer Dimension

    CREATE VIEW Analytics.vw_dim_customers AS
SELECT 
    customer_id,
    UPPER(customer_city) AS customer_city,
    customer_state
FROM customers;

--Create Seller Dimension

CREATE VIEW Analytics.vw_dim_sellers AS
SELECT 
    seller_id,
    UPPER(seller_city) AS seller_city,
    seller_state
FROM sellers;

--Create Date Dimension

CREATE TABLE Analytics.DimDate (
    DateKey DATE PRIMARY KEY,
    Year INT,
    Month INT,
    MonthName VARCHAR(15),
    MonthYear VARCHAR(20),
    Quarter INT,
    DayOfWeek INT,
    DayName VARCHAR(15),
    IsWeekend BIT
);

DECLARE @StartDate DATE = '2016-01-01';
DECLARE @EndDate DATE = '2019-01-01';

WHILE @StartDate < @EndDate
BEGIN
    INSERT INTO Analytics.DimDate
    SELECT 
        @StartDate,
        YEAR(@StartDate),
        MONTH(@StartDate),
        DATENAME(MONTH, @StartDate),
        FORMAT(@StartDate, 'yyyy-MM'),
        DATEPART(QUARTER, @StartDate),
        DATEPART(WEEKDAY, @StartDate),
        DATENAME(WEEKDAY, @StartDate),
        CASE 
            WHEN DATENAME(WEEKDAY, @StartDate) IN ('Saturday', 'Sunday') 
            THEN 1 ELSE 0 
        END;

    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;

SELECT COUNT(*) FROM Analytics.DimDate;

--Create a CLEAN geolocation base

CREATE VIEW Analytics.vw_geo_base AS
SELECT 
    geolocation_zip_code_prefix AS zip_prefix,
    AVG(geolocation_lat) AS latitude,
    AVG(geolocation_lng) AS longitude
FROM geolocation
GROUP BY geolocation_zip_code_prefix;

--Update Customer Dimension

CREATE OR ALTER VIEW Analytics.vw_dim_customers AS
SELECT 
    c.customer_id,
    UPPER(c.customer_city) AS customer_city,
    c.customer_state,
    g.latitude  AS customer_latitude,
    g.longitude AS customer_longitude
FROM customers c
LEFT JOIN Analytics.vw_geo_base g
    ON c.customer_zip_code_prefix = g.zip_prefix;

    --Update Seller Dimension

    CREATE OR ALTER VIEW Analytics.vw_dim_sellers AS
SELECT 
    s.seller_id,
    UPPER(s.seller_city) AS seller_city,
    s.seller_state,
    g.latitude  AS seller_latitude,
    g.longitude AS seller_longitude
FROM sellers s
LEFT JOIN Analytics.vw_geo_base g
    ON s.seller_zip_code_prefix = g.zip_prefix;

    -- check coverage
SELECT 
  COUNT(*) AS total_customers,
  COUNT(customer_latitude) AS customers_with_geo
FROM Analytics.vw_dim_customers;

SELECT 
  COUNT(*) AS total_sellers,
  COUNT(seller_latitude) AS sellers_with_geo
FROM Analytics.vw_dim_sellers;

--create fact table order item

CREATE VIEW Analytics.vw_fact_order_items AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,

    o.customer_id,
    c.customer_state,

    -- Date key for relationship
    CAST(o.order_purchase_timestamp AS DATE) AS order_date,

    -- Delivery metrics
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS actual_delivery_days,
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_estimated_delivery_date) AS estimated_delivery_days,
    DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) AS delay_days,

    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1
        ELSE 0
    END AS is_on_time,

    -- Financials (item level)
    oi.price,
    oi.freight_value,

    -- Review (order-level but joined)
    r.review_score

FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;




