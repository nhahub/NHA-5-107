USE RetailChurn;
GO

CREATE OR ALTER PROCEDURE bronze.load_customers AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING CUSTOMERS TABLE IN BRONZE LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();
---------------------------------------
        INSERT INTO bronze.customers(
                [customer_id],
                [customer_name],
                [customer_age],
                [customer_gender],
                [customer_segment],
                [customer_city],
                [customer_state],
                [customer_country],
                [customer_region],
                [customer_postal_code],
                [customer_acquisition_cost]
        )
---------------------------------------
        SELECT 
                [customer_id],
                [customer_name],
                [customer_age],
                [gender],
                [customer_segment],
                [customer_city],
                [customer_state],
                [customer_country],
                [region],
                [customer_postal_code],
                [customer_acquisition_cost]
        FROM staging.customers
---------------------------------------
        EXCEPT
        SELECT 
                [customer_id],
                [customer_name],
                [customer_age],
                [customer_gender],
                [customer_segment],
                [customer_city],
                [customer_state],
                [customer_country],
                [customer_region],
                [customer_postal_code],
                [customer_acquisition_cost]
        FROM bronze.customers;
---------------------------------------
        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED CUSTOMERS TABLE IN BRONZE LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE bronze.load_products AS
BEGIN
        
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING PRODUCTS TABLE IN BRONZE LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();
---------------------------------------
        INSERT INTO bronze.products(
                [product_id],
                [product_name],
                [product_category],
                [product_subcategory],
                [product_brand],
                [product_supplier],
                [product_unit_price],
                [product_cost],
                [product_rating]
        )
---------------------------------------
        SELECT 
                [product_id],
                [product_name],
                [product_category],
                [product_subcategory],
                [brand],
                [supplier],
                [unit_price],
                [product_cost],
                [product_rating]
        FROM staging.products
---------------------------------------
        EXCEPT
        SELECT 
                [product_id],
                [product_name],
                [product_category],
                [product_subcategory],
                [product_brand],
                [product_supplier],
                [product_unit_price],
                [product_cost],
                [product_rating]
        FROM bronze.products;
---------------------------------------
        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED PRODUCTS TABLE IN BRONZE LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE bronze.load_order_items AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING ORDER ITEMS TABLE IN BRONZE LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();
---------------------------------------
        INSERT INTO bronze.order_items(
                [order_id],
                [product_id],
                [quantity],
                [unit_price],
                [discount_percentage],
                [discount_amount],
                [gross_sales],
                [tax_amount],
                [shipping_cost],
                [net_sales],
                [product_cost],
                [profit]
        )
---------------------------------------
        SELECT 
                [order_id],
                [product_id],
                [quantity],
                [unit_price],
                [discount_percentage],
                [discount_amount],
                [gross_sales],
                [tax_amount],
                [shipping_cost],
                [net_sales],
                [product_cost],
                [profit]
        FROM staging.order_items
---------------------------------------
        EXCEPT
        SELECT 
                [order_id],
                [product_id],
                [quantity],
                [unit_price],
                [discount_percentage],
                [discount_amount],
                [gross_sales],
                [tax_amount],
                [shipping_cost],
                [net_sales],
                [product_cost],
                [profit]
        FROM bronze.order_items;
---------------------------------------
        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED ORDER ITEMS TABLE IN BRONZE LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE bronze.load_orders AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING ORDERS TABLE IN BRONZE LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();
---------------------------------------
        INSERT INTO bronze.orders(
                [order_id],
                [order_date],
                [order_time],
                [order_status],
                [sales_channel],
                [customer_id],
                [customer_name],
                [customer_age],
                [customer_gender],
                [customer_segment],
                [customer_type],
                [customer_city],
                [customer_state],
                [customer_country],
                [customer_region],
                [customer_postal_code],
                [payment_method],
                [payment_status],
                [currency],
                [shipping_method],
                [warehouse],
                [delivery_days],
                [estimated_delivery_days],
                [delivery_status],
                [return_status],
                [return_reason],
                [customer_rating],
                [review_sentiment],
                [customer_review],
                [marketing_channel],
                [campaign_name],
                [coupon_code],
                [loyalty_points_earned],
                [loyalty_points_redeemed],
                [quantity],
                [gross_sales],
                [discount_amount],
                [tax_amount],
                [shipping_cost],
                [net_sales],
                [product_cost],
                [profit],
                [profit_margin_percentage],
                [customer_lifetime_value],
                [is_repeat_customer],
                [customer_order_count]
        )
---------------------------------------
        SELECT 
                [order_id],
                [order_date],
                [order_time],
                [order_status],
                [sales_channel],
                [customer_id],
                [customer_name],
                [customer_age],
                [gender],
                [customer_segment],
                [customer_type],
                [customer_city],
                [customer_state],
                [customer_country],
                [region],
                [customer_postal_code],
                [payment_method],
                [payment_status],
                [currency],
                [shipping_method],
                [warehouse],
                [delivery_days],
                [estimated_delivery_days],
                [delivery_status],
                [return_status],
                [return_reason],
                [customer_rating],
                [review_sentiment],
                [customer_review],
                [marketing_channel],
                [campaign_name],
                [coupon_code],
                [loyalty_points_earned],
                [loyalty_points_redeemed],
                [quantity],
                [gross_sales],
                [discount_amount],
                [tax_amount],
                [shipping_cost],
                [net_sales],
                [product_cost],
                [profit],
                [profit_margin_percentage],
                [customer_lifetime_value],
                [is_repeat_customer],
                [customer_order_count]
        FROM staging.orders
---------------------------------------
        EXCEPT
        SELECT 
                [order_id],
                [order_date],
                [order_time],
                [order_status],
                [sales_channel],
                [customer_id],
                [customer_name],
                [customer_age],
                [customer_gender],
                [customer_segment],
                [customer_type],
                [customer_city],
                [customer_state],
                [customer_country],
                [customer_region],
                [customer_postal_code],
                [payment_method],
                [payment_status],
                [currency],
                [shipping_method],
                [warehouse],
                [delivery_days],
                [estimated_delivery_days],
                [delivery_status],
                [return_status],
                [return_reason],
                [customer_rating],
                [review_sentiment],
                [customer_review],
                [marketing_channel],
                [campaign_name],
                [coupon_code],
                [loyalty_points_earned],
                [loyalty_points_redeemed],
                [quantity],
                [gross_sales],
                [discount_amount],
                [tax_amount],
                [shipping_cost],
                [net_sales],
                [product_cost],
                [profit],
                [profit_margin_percentage],
                [customer_lifetime_value],
                [is_repeat_customer],
                [customer_order_count]
        FROM bronze.orders;
---------------------------------------
        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED ORDERS TABLE IN BRONZE LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO