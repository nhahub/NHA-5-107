USE RetailChurn;
GO


CREATE OR ALTER PROCEDURE gold.load_dim_customer AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING DIM CUSTOMER TABLE IN GOLD LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();

        TRUNCATE TABLE gold.dim_customer;

        INSERT INTO gold.dim_customer(
                [customer_id],
                [customer_name],
                [customer_age],
                [customer_age_group],
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
                [customer_age],
                CASE
                        WHEN [customer_age] IS NULL THEN 'Unknown'
                        WHEN [customer_age] < 25    THEN '18-24'
                        WHEN [customer_age] < 35    THEN '25-34'
                        WHEN [customer_age] < 45    THEN '35-44'
                        WHEN [customer_age] < 55    THEN '45-54'
                        WHEN [customer_age] < 65    THEN '55-64'
                        ELSE '65+'
                END,
                [customer_gender],
                [customer_segment],
                [customer_city],
                [customer_state],
                [customer_country],
                [customer_region],
                [customer_postal_code],
                [customer_acquisition_cost]
        FROM silver.customers;

        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED DIM CUSTOMER TABLE IN GOLD LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE gold.load_dim_product AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING DIM PRODUCT TABLE IN GOLD LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();

        TRUNCATE TABLE gold.dim_product;

        INSERT INTO gold.dim_product(
                [product_id],
                [product_name],
                [product_category],
                [product_subcategory],
                [product_brand],
                [product_supplier],
                [product_unit_price],
                [product_cost],
                [product_margin_percentage],
                [product_rating]
        )

        SELECT
                [product_id],
                [product_name],
                [product_category],
                [product_subcategory],
                [product_brand],
                [product_supplier],
                [product_unit_price],
                [product_cost],
                CAST(100.0 * ([product_unit_price] - [product_cost]) / NULLIF([product_unit_price], 0) AS DECIMAL(7,2)),
                [product_rating]
        FROM silver.products;

        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED DIM PRODUCT TABLE IN GOLD LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE gold.load_dim_date AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        DECLARE @MIN_DATE DATE, @MAX_DATE DATE;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING DIM DATE TABLE IN GOLD LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();


        TRUNCATE TABLE gold.dim_date;


        SELECT
                @MIN_DATE = DATEFROMPARTS(YEAR(MIN([order_date])), 1, 1),
                @MAX_DATE = DATEFROMPARTS(YEAR(MAX([order_date])), 12, 31)
        FROM silver.orders;

        WITH dates AS (
                SELECT @MIN_DATE AS [full_date]
                UNION ALL
                SELECT DATEADD(DAY, 1, [full_date])
                FROM dates
                WHERE [full_date] < @MAX_DATE
        )
        INSERT INTO gold.dim_date(
                [date_key],
                [full_date],
                [day_of_month],
                [day_of_week],
                [day_name],
                [week_of_year],
                [month_number],
                [month_name],
                [quarter],
                [year],
                [is_weekend]
        )

        SELECT
                CAST(CONVERT(CHAR(8), d.[full_date], 112) AS INT),
                d.[full_date],
                DAY(d.[full_date]),
                w.[dow],
                CHOOSE(w.[dow], 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                DATEPART(ISO_WEEK, d.[full_date]),
                MONTH(d.[full_date]),
                CHOOSE(MONTH(d.[full_date]), 'January', 'February', 'March', 'April', 'May', 'June',
                                             'July', 'August', 'September', 'October', 'November', 'December'),
                DATEPART(QUARTER, d.[full_date]),
                YEAR(d.[full_date]),
                CASE WHEN w.[dow] IN (6, 7) THEN 1 ELSE 0 END
        FROM dates AS d
        CROSS APPLY (
                SELECT (DATEDIFF(DAY, '19000101', d.[full_date]) % 7) + 1 AS [dow]
        ) AS w
        WHERE d.[full_date] IS NOT NULL
        OPTION (MAXRECURSION 0);

        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED DIM DATE TABLE IN GOLD LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE gold.load_fact_orders AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING FACT ORDERS TABLE IN GOLD LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();

        TRUNCATE TABLE gold.fact_orders;

        INSERT INTO gold.fact_orders(
                [order_id],
                [date_key],
                [customer_key],
                [order_time],
                [order_status],
                [sales_channel],
                [customer_type],
                [payment_method],
                [payment_status],
                [currency],
                [shipping_method],
                [warehouse],
                [delivery_status],
                [delivery_days],
                [estimated_delivery_days],
                [delivery_delay_days],
                [return_status],
                [return_reason],
                [is_returned],
                [customer_rating],
                [review_sentiment],
                [marketing_channel],
                [campaign_name],
                [coupon_code],
                [has_coupon],
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
                [profit_margin_percentage]
        )

        SELECT
                o.[order_id],
                CAST(CONVERT(CHAR(8), o.[order_date], 112) AS INT),
                c.[customer_key],
                o.[order_time],
                o.[order_status],
                o.[sales_channel],
                o.[customer_type],
                o.[payment_method],
                o.[payment_status],
                o.[currency],
                o.[shipping_method],
                o.[warehouse],
                o.[delivery_status],
                o.[delivery_days],
                o.[estimated_delivery_days],
                o.[delivery_days] - o.[estimated_delivery_days],
                ISNULL(o.[return_status], 'Not Returned'),
                o.[return_reason],
                CASE WHEN o.[return_status] = 'Returned' THEN 1 ELSE 0 END,
                o.[customer_rating],
                o.[review_sentiment],
                ISNULL(o.[marketing_channel], 'Unknown'),
                ISNULL(o.[campaign_name], 'No Campaign'),
                o.[coupon_code],
                CASE WHEN o.[coupon_code] IS NOT NULL THEN 1 ELSE 0 END,
                o.[loyalty_points_earned],
                o.[loyalty_points_redeemed],
                o.[quantity],
                o.[gross_sales],
                o.[discount_amount],
                o.[tax_amount],
                o.[shipping_cost],
                o.[net_sales],
                o.[product_cost],
                o.[profit],
                o.[profit_margin_percentage]
        FROM silver.orders AS o
        LEFT JOIN gold.dim_customer AS c
                ON o.[customer_id] = c.[customer_id];

        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED FACT ORDERS TABLE IN GOLD LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE gold.load_fact_order_items AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING FACT ORDER ITEMS TABLE IN GOLD LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();

        TRUNCATE TABLE gold.fact_order_items;

        INSERT INTO gold.fact_order_items(
                [order_key],
                [order_id],
                [date_key],
                [customer_key],
                [product_key],
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
                o.[order_key],
                i.[order_id],
                o.[date_key],
                o.[customer_key],
                p.[product_key],
                i.[quantity],
                i.[unit_price],
                i.[discount_percentage],
                i.[discount_amount],
                i.[gross_sales],
                i.[tax_amount],
                i.[shipping_cost],
                i.[net_sales],
                i.[product_cost],
                i.[profit],
                i.[is_quantity_corrected],
                i.[is_net_sales_corrected]
        FROM silver.order_items AS i
        LEFT JOIN gold.fact_orders AS o
                ON i.[order_id] = o.[order_id]
        LEFT JOIN gold.dim_product AS p
                ON i.[product_id] = p.[product_id];

        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED FACT ORDER ITEMS TABLE IN GOLD LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE gold.load_customer_summary
        @CHURN_THRESHOLD_DAYS INT = 365
AS
BEGIN
        DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
        DECLARE @SNAPSHOT_DATE DATE;
        PRINT ''
        PRINT '================================================================';
        PRINT ' POPULATING CUSTOMER SUMMARY TABLE IN GOLD LAYER';
        PRINT '================================================================';
        SET @START_TIME = GETDATE();

        TRUNCATE TABLE gold.customer_summary;

        SELECT @SNAPSHOT_DATE = MAX(d.[full_date])
        FROM gold.fact_orders AS o
        INNER JOIN gold.dim_date AS d
                ON o.[date_key] = d.[date_key];

        INSERT INTO gold.customer_summary(
                [customer_key],
                [customer_id],
                [total_orders],
                [completed_orders],
                [cancelled_orders],
                [returned_orders],
                [return_rate_percentage],
                [total_quantity],
                [total_net_sales],
                [total_profit],
                [avg_order_value],
                [avg_customer_rating],
                [first_order_date],
                [last_order_date],
                [snapshot_date],
                [days_since_last_order],
                [churn_threshold_days],
                [is_churned]
        )

        SELECT
                [customer_key],
                [customer_id],
                [total_orders],
                [completed_orders],
                [cancelled_orders],
                [returned_orders],
                CAST(100.0 * [returned_orders] / NULLIF([completed_orders] + [returned_orders], 0) AS DECIMAL(5,2)),
                [total_quantity],
                [total_net_sales],
                [total_profit],
                CAST([total_net_sales] / NULLIF([completed_orders], 0) AS DECIMAL(12,2)),
                CAST([avg_customer_rating] AS DECIMAL(3,2)),
                [first_order_date],
                [last_order_date],
                @SNAPSHOT_DATE,
                DATEDIFF(DAY, [last_order_date], @SNAPSHOT_DATE),
                @CHURN_THRESHOLD_DAYS,
                CASE
                        WHEN [last_order_date] IS NULL THEN NULL
                        WHEN DATEDIFF(DAY, [last_order_date], @SNAPSHOT_DATE) > @CHURN_THRESHOLD_DAYS THEN 1
                        ELSE 0
                END
        FROM (
                SELECT
                        c.[customer_key],
                        c.[customer_id],
                        COUNT(o.[order_key])                                                         AS [total_orders],
                        SUM(CASE WHEN o.[order_status] = 'Completed' THEN 1 ELSE 0 END)              AS [completed_orders],
                        SUM(CASE WHEN o.[order_status] = 'Cancelled' THEN 1 ELSE 0 END)              AS [cancelled_orders],
                        SUM(CASE WHEN o.[order_status] = 'Returned'  THEN 1 ELSE 0 END)              AS [returned_orders],
                        SUM(CASE WHEN o.[order_status] = 'Completed' THEN o.[quantity]  ELSE 0 END)  AS [total_quantity],
                        SUM(CASE WHEN o.[order_status] = 'Completed' THEN o.[net_sales] ELSE 0 END)  AS [total_net_sales],
                        SUM(CASE WHEN o.[order_status] = 'Completed' THEN o.[profit]    ELSE 0 END)  AS [total_profit],
                        AVG(o.[customer_rating])                                                     AS [avg_customer_rating],
                        MIN(CASE WHEN o.[order_status] = 'Completed' THEN d.[full_date] END)         AS [first_order_date],
                        MAX(CASE WHEN o.[order_status] = 'Completed' THEN d.[full_date] END)         AS [last_order_date]
                FROM gold.dim_customer AS c
                LEFT JOIN gold.fact_orders AS o
                        ON c.[customer_key] = o.[customer_key]
                LEFT JOIN gold.dim_date AS d
                        ON o.[date_key] = d.[date_key]
                GROUP BY
                        c.[customer_key],
                        c.[customer_id]
        ) AS s;

        SET @END_TIME = GETDATE();
        PRINT ' > POPULATED CUSTOMER SUMMARY TABLE IN GOLD LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO
