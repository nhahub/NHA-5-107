USE RetailChurn;
GO



CREATE OR ALTER PROCEDURE silver.load_customers AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING CUSTOMERS TABLE IN SILVER LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();

        TRUNCATE TABLE silver.customers;

        INSERT INTO silver.customers(
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

        SELECT
                [customer_id],
                [customer_name],
                CASE
                        WHEN TRY_CAST([customer_age] AS INT) BETWEEN 18 AND 100
                        THEN TRY_CAST([customer_age] AS INT)
                END,
                CASE LOWER([customer_gender])
                        WHEN 'female'     THEN 'Female'
                        WHEN 'male'       THEN 'Male'
                        WHEN 'non-binary' THEN 'Non-Binary'
                        ELSE 'Unknown'
                END,
                CASE LOWER([customer_segment])
                        WHEN 'consumer'     THEN 'Consumer'
                        WHEN 'premium'      THEN 'Premium'
                        WHEN 'premium-tier' THEN 'Premium'
                        WHEN 'vip'          THEN 'VIP'
                        WHEN 'business'     THEN 'Business'
                        WHEN 'corporate'    THEN 'Business'
                        ELSE 'Unknown'
                END,
                [customer_city],
                [customer_state],
                CASE LOWER([customer_country])
                        WHEN 'usa'            THEN 'USA'
                        WHEN 'u.s.a.'         THEN 'USA'
                        WHEN 'us'             THEN 'USA'
                        WHEN 'united states'  THEN 'USA'
                        WHEN 'uk'             THEN 'UK'
                        WHEN 'united kingdom' THEN 'UK'
                        WHEN 'great britain'  THEN 'UK'
                        WHEN 'germany'        THEN 'Germany'
                        WHEN 'deutschland'    THEN 'Germany'
                        WHEN 'uae'            THEN 'UAE'
                        WHEN 'u.a.e.'         THEN 'UAE'
                        ELSE [customer_country]
                END,
                [customer_region],
                CASE
                        WHEN [customer_postal_code] NOT LIKE '%[^0-9]%' AND LEN([customer_postal_code]) < 5
                        THEN RIGHT('00000' + [customer_postal_code], 5)
                        ELSE [customer_postal_code]
                END,

                ABS(TRY_CAST([customer_acquisition_cost] AS DECIMAL(10,2)))
        FROM (
                SELECT
                        NULLIF(TRIM([customer_id]), '')                 AS [customer_id],
                        NULLIF(TRIM([customer_name]), '')               AS [customer_name],
                        NULLIF(TRIM([customer_age]), '')                AS [customer_age],
                        NULLIF(TRIM([customer_gender]), '')             AS [customer_gender],
                        NULLIF(TRIM([customer_segment]), '')            AS [customer_segment],
                        NULLIF(TRIM([customer_city]), '')               AS [customer_city],
                        NULLIF(TRIM([customer_state]), '')              AS [customer_state],
                        NULLIF(TRIM([customer_country]), '')            AS [customer_country],
                        NULLIF(TRIM([customer_region]), '')             AS [customer_region],
                        NULLIF(TRIM([customer_postal_code]), '')        AS [customer_postal_code],
                        NULLIF(TRIM([customer_acquisition_cost]), '')   AS [customer_acquisition_cost],
                        ROW_NUMBER() OVER (
                                PARTITION BY NULLIF(TRIM([customer_id]), '')
                                ORDER BY [bronze_created_at] DESC, [bronze_id] DESC
                        ) AS [rn]
                FROM bronze.customers
        ) AS b
        WHERE [rn] = 1
          AND [customer_id] IS NOT NULL;

        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED CUSTOMERS TABLE IN SILVER LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE silver.load_products AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING PRODUCTS TABLE IN SILVER LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();

        TRUNCATE TABLE silver.products;

        INSERT INTO silver.products(
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

        SELECT
                [product_id],
                [product_name],
                [product_category],
                [product_subcategory],
                [product_brand],
                [product_supplier],
                CASE
                        WHEN TRY_CAST([product_unit_price] AS DECIMAL(10,2)) > 0
                        THEN TRY_CAST([product_unit_price] AS DECIMAL(10,2))
                END,
                CASE
                        WHEN TRY_CAST([product_cost] AS DECIMAL(10,2)) > 0
                        THEN TRY_CAST([product_cost] AS DECIMAL(10,2))
                END,
                CASE
                        WHEN TRY_CAST([product_rating] AS DECIMAL(3,1)) BETWEEN 0 AND 5
                        THEN TRY_CAST([product_rating] AS DECIMAL(3,1))
                END
        FROM (
                SELECT
                        NULLIF(TRIM([product_id]), '')              AS [product_id],
                        NULLIF(TRIM([product_name]), '')            AS [product_name],
                        NULLIF(TRIM([product_category]), '')        AS [product_category],
                        NULLIF(TRIM([product_subcategory]), '')     AS [product_subcategory],
                        NULLIF(TRIM([product_brand]), '')           AS [product_brand],
                        NULLIF(TRIM([product_supplier]), '')        AS [product_supplier],
                        NULLIF(TRIM([product_unit_price]), '')      AS [product_unit_price],
                        NULLIF(TRIM([product_cost]), '')            AS [product_cost],
                        NULLIF(TRIM([product_rating]), '')          AS [product_rating],
                        ROW_NUMBER() OVER (
                                PARTITION BY NULLIF(TRIM([product_id]), '')
                                ORDER BY [bronze_created_at] DESC, [bronze_id] DESC
                        ) AS [rn]
                FROM bronze.products
        ) AS b
        WHERE [rn] = 1
          AND [product_id] IS NOT NULL;

        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED PRODUCTS TABLE IN SILVER LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE silver.load_order_items AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING ORDER ITEMS TABLE IN SILVER LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();

        TRUNCATE TABLE silver.order_items;

        INSERT INTO silver.order_items(
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
                [profit],
                [is_quantity_corrected],
                [is_net_sales_corrected]
        )
        SELECT
                b.[order_id],
                b.[product_id],
                CASE
                        WHEN t.[qty] > 0 THEN t.[qty]
                        WHEN t.[price] > 0 THEN CAST(ROUND(t.[gross_sales] / t.[price], 0) AS INT)
                END,
                t.[price],
                ISNULL(
                        t.[discount_pct],
                        CASE
                                WHEN t.[gross_sales] > 0 THEN CAST(t.[discount_amount] / t.[gross_sales] AS DECIMAL(9,6))
                                ELSE 0
                        END
                ),
                t.[discount_amount],
                t.[gross_sales],
                t.[tax_amount],
                t.[shipping_cost],
                ISNULL(c.[net_calc], t.[net_sales]),
                t.[product_cost],
                t.[profit],
                CASE WHEN t.[qty] > 0 THEN 0 ELSE 1 END,
                CASE WHEN ABS(c.[net_calc] - t.[net_sales]) > 0.02 THEN 1 ELSE 0 END
        FROM (
                SELECT
                        NULLIF(TRIM([order_id]), '')                AS [order_id],
                        NULLIF(TRIM([product_id]), '')              AS [product_id],
                        NULLIF(TRIM([quantity]), '')                AS [quantity],
                        NULLIF(TRIM([unit_price]), '')              AS [unit_price],
                        NULLIF(TRIM([discount_percentage]), '')     AS [discount_percentage],
                        NULLIF(TRIM([discount_amount]), '')         AS [discount_amount],
                        NULLIF(TRIM([gross_sales]), '')             AS [gross_sales],
                        NULLIF(TRIM([tax_amount]), '')              AS [tax_amount],
                        NULLIF(TRIM([shipping_cost]), '')           AS [shipping_cost],
                        NULLIF(TRIM([net_sales]), '')               AS [net_sales],
                        NULLIF(TRIM([product_cost]), '')            AS [product_cost],
                        NULLIF(TRIM([profit]), '')                  AS [profit],
                        ROW_NUMBER() OVER (
                                PARTITION BY [order_id], [product_id], [quantity], [unit_price], [discount_percentage],
                                             [discount_amount], [gross_sales], [tax_amount], [shipping_cost],
                                             [net_sales], [product_cost], [profit]
                                ORDER BY [bronze_id]
                        ) AS [rn]
                FROM bronze.order_items
        ) AS b
        CROSS APPLY (
                SELECT
                        TRY_CAST(b.[quantity] AS INT)                                   AS [qty],
                        TRY_CAST(b.[unit_price] AS DECIMAL(10,2))                       AS [price],

                        TRY_CAST(TRY_CAST(b.[discount_percentage] AS FLOAT) AS DECIMAL(9,6)) AS [discount_pct],
                        TRY_CAST(b.[discount_amount] AS DECIMAL(12,2))                  AS [discount_amount],
                        TRY_CAST(b.[gross_sales] AS DECIMAL(12,2))                      AS [gross_sales],
                        TRY_CAST(b.[tax_amount] AS DECIMAL(12,2))                       AS [tax_amount],
                        TRY_CAST(b.[shipping_cost] AS DECIMAL(12,2))                    AS [shipping_cost],
                        TRY_CAST(b.[net_sales] AS DECIMAL(12,2))                        AS [net_sales],
                        TRY_CAST(b.[product_cost] AS DECIMAL(12,2))                     AS [product_cost],
                        TRY_CAST(b.[profit] AS DECIMAL(12,2))                           AS [profit]
        ) AS t
        CROSS APPLY (
                SELECT t.[gross_sales] - t.[discount_amount] + t.[tax_amount] + t.[shipping_cost] AS [net_calc]
        ) AS c
        WHERE b.[rn] = 1
          AND b.[order_id] IS NOT NULL
          AND b.[product_id] IS NOT NULL;

        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED ORDER ITEMS TABLE IN SILVER LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE silver.load_orders AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING ORDERS TABLE IN SILVER LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();

        TRUNCATE TABLE silver.orders;

        INSERT INTO silver.orders(
                [order_id],
                [order_date],
                [order_time],
                [order_status],
                [sales_channel],
                [customer_id],
                [customer_type],
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

        SELECT
                [order_id],
                CASE
                        WHEN [order_date] LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
                                THEN TRY_CONVERT(DATE, [order_date], 23)
                        WHEN [order_date] LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]'
                                THEN TRY_CONVERT(DATE, REPLACE([order_date], '/', '-'), 23)
                        WHEN [order_date] LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
                                THEN TRY_CONVERT(DATE, [order_date], 101)
                        WHEN [order_date] LIKE '[0-9][0-9]-[A-Za-z][A-Za-z][A-Za-z]-[0-9][0-9][0-9][0-9]'
                                THEN TRY_CONVERT(DATE,
                                        RIGHT([order_date], 4) + '-'
                                        + RIGHT('0' + CAST((CHARINDEX(SUBSTRING([order_date], 4, 3), 'JanFebMarAprMayJunJulAugSepOctNovDec') + 2) / 3 AS VARCHAR(2)), 2) + '-'
                                        + LEFT([order_date], 2), 23)
                END,
                TRY_CAST([order_time] AS TIME(0)),
                [order_status],
                [sales_channel],
                [customer_id],
                [customer_type],
                [payment_method],
                [payment_status],
                UPPER([currency]),
                [shipping_method],
                UPPER([warehouse]),

                TRY_CAST(TRY_CAST([delivery_days] AS DECIMAL(10,1)) AS INT),
                TRY_CAST(TRY_CAST([estimated_delivery_days] AS DECIMAL(10,1)) AS INT),
                [delivery_status],
                [return_status],
                [return_reason],
                CASE
                        WHEN TRY_CAST([customer_rating] AS DECIMAL(3,1)) BETWEEN 1 AND 5
                        THEN TRY_CAST([customer_rating] AS DECIMAL(3,1))
                END,
                [review_sentiment],
                [customer_review],
                [marketing_channel],
                [campaign_name],
                [coupon_code],
                TRY_CAST([loyalty_points_earned] AS INT),
                TRY_CAST([loyalty_points_redeemed] AS INT),
                TRY_CAST([quantity] AS INT),
                TRY_CAST([gross_sales] AS DECIMAL(12,2)),
                TRY_CAST([discount_amount] AS DECIMAL(12,2)),
                TRY_CAST([tax_amount] AS DECIMAL(12,2)),
                TRY_CAST([shipping_cost] AS DECIMAL(12,2)),
                TRY_CAST([net_sales] AS DECIMAL(12,2)),
                TRY_CAST([product_cost] AS DECIMAL(12,2)),
                TRY_CAST([profit] AS DECIMAL(12,2)),
                TRY_CAST([profit_margin_percentage] AS DECIMAL(7,2)),
                TRY_CAST([customer_lifetime_value] AS DECIMAL(12,2)),
                TRY_CAST([is_repeat_customer] AS BIT),
                TRY_CAST([customer_order_count] AS INT)
        FROM (
                SELECT
                        NULLIF(TRIM([order_id]), '')                    AS [order_id],
                        NULLIF(TRIM([order_date]), '')                  AS [order_date],
                        NULLIF(TRIM([order_time]), '')                  AS [order_time],
                        NULLIF(TRIM([order_status]), '')                AS [order_status],
                        NULLIF(TRIM([sales_channel]), '')               AS [sales_channel],
                        NULLIF(TRIM([customer_id]), '')                 AS [customer_id],
                        NULLIF(TRIM([customer_type]), '')               AS [customer_type],
                        NULLIF(TRIM([payment_method]), '')              AS [payment_method],
                        NULLIF(TRIM([payment_status]), '')              AS [payment_status],
                        NULLIF(TRIM([currency]), '')                    AS [currency],
                        NULLIF(TRIM([shipping_method]), '')             AS [shipping_method],
                        NULLIF(TRIM([warehouse]), '')                   AS [warehouse],
                        NULLIF(TRIM([delivery_days]), '')               AS [delivery_days],
                        NULLIF(TRIM([estimated_delivery_days]), '')     AS [estimated_delivery_days],
                        NULLIF(TRIM([delivery_status]), '')             AS [delivery_status],
                        NULLIF(TRIM([return_status]), '')               AS [return_status],
                        NULLIF(TRIM([return_reason]), '')               AS [return_reason],
                        NULLIF(TRIM([customer_rating]), '')             AS [customer_rating],
                        NULLIF(TRIM([review_sentiment]), '')            AS [review_sentiment],
                        NULLIF(TRIM([customer_review]), '')             AS [customer_review],
                        NULLIF(TRIM([marketing_channel]), '')           AS [marketing_channel],
                        NULLIF(TRIM([campaign_name]), '')               AS [campaign_name],
                        NULLIF(TRIM([coupon_code]), '')                 AS [coupon_code],
                        NULLIF(TRIM([loyalty_points_earned]), '')       AS [loyalty_points_earned],
                        NULLIF(TRIM([loyalty_points_redeemed]), '')     AS [loyalty_points_redeemed],
                        NULLIF(TRIM([quantity]), '')                    AS [quantity],
                        NULLIF(TRIM([gross_sales]), '')                 AS [gross_sales],
                        NULLIF(TRIM([discount_amount]), '')             AS [discount_amount],
                        NULLIF(TRIM([tax_amount]), '')                  AS [tax_amount],
                        NULLIF(TRIM([shipping_cost]), '')               AS [shipping_cost],
                        NULLIF(TRIM([net_sales]), '')                   AS [net_sales],
                        NULLIF(TRIM([product_cost]), '')                AS [product_cost],
                        NULLIF(TRIM([profit]), '')                      AS [profit],
                        NULLIF(TRIM([profit_margin_percentage]), '')    AS [profit_margin_percentage],
                        NULLIF(TRIM([customer_lifetime_value]), '')     AS [customer_lifetime_value],
                        NULLIF(TRIM([is_repeat_customer]), '')          AS [is_repeat_customer],
                        NULLIF(TRIM([customer_order_count]), '')        AS [customer_order_count],
                        ROW_NUMBER() OVER (
                                PARTITION BY NULLIF(TRIM([order_id]), '')
                                ORDER BY [bronze_created_at] DESC, [bronze_id] DESC
                        ) AS [rn]
                FROM bronze.orders
        ) AS b
        WHERE [rn] = 1
          AND [order_id] IS NOT NULL;
        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED ORDERS TABLE IN SILVER LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO
