USE RetailChurn;
GO


IF OBJECT_ID('gold.dim_customer', 'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_customer (
        customer_key                INT IDENTITY (1,1) PRIMARY KEY,
        gold_created_at             DATETIME2 DEFAULT SYSDATETIME(),
        customer_id                 NVARCHAR(50) NOT NULL UNIQUE,
        customer_name               NVARCHAR(255),
        customer_age                INT,
        customer_age_group          NVARCHAR(20),
        customer_gender             NVARCHAR(50),
        customer_segment            NVARCHAR(50),
        customer_city               NVARCHAR(255),
        customer_state              NVARCHAR(255),
        customer_country            NVARCHAR(100),
        customer_region             NVARCHAR(50),
        customer_postal_code        NVARCHAR(20),
        customer_acquisition_cost   DECIMAL(10,2)
    );
END
GO

IF OBJECT_ID('gold.dim_product', 'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_product (
        product_key                 INT IDENTITY (1,1) PRIMARY KEY,
        gold_created_at             DATETIME2 DEFAULT SYSDATETIME(),
        product_id                  NVARCHAR(50) NOT NULL UNIQUE,
        product_name                NVARCHAR(255),
        product_category            NVARCHAR(255),
        product_subcategory         NVARCHAR(255),
        product_brand               NVARCHAR(255),
        product_supplier            NVARCHAR(255),
        product_unit_price          DECIMAL(10,2),
        product_cost                DECIMAL(10,2),
        product_margin_percentage   DECIMAL(7,2),
        product_rating              DECIMAL(3,1)
    );
END
GO

IF OBJECT_ID('gold.dim_date', 'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_date (
        date_key                    INT PRIMARY KEY,
        gold_created_at             DATETIME2 DEFAULT SYSDATETIME(),
        full_date                   DATE NOT NULL,
        day_of_month                INT,
        day_of_week                 INT,
        day_name                    NVARCHAR(20),
        week_of_year                INT,
        month_number                INT,
        month_name                  NVARCHAR(20),
        quarter                     INT,
        year                        INT,
        is_weekend                  BIT
    );
END
GO


IF OBJECT_ID('gold.fact_orders', 'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_orders (
        order_key                   INT IDENTITY (1,1) PRIMARY KEY,
        gold_created_at             DATETIME2 DEFAULT SYSDATETIME(),
        order_id                    NVARCHAR(50) NOT NULL UNIQUE,
        date_key                    INT,
        customer_key                INT,
        order_time                  TIME(0),
        order_status                NVARCHAR(50),
        sales_channel               NVARCHAR(50),
        customer_type               NVARCHAR(50),
        payment_method              NVARCHAR(50),
        payment_status              NVARCHAR(50),
        currency                    NVARCHAR(10),
        shipping_method             NVARCHAR(50),
        warehouse                   NVARCHAR(50),
        delivery_status             NVARCHAR(50),
        delivery_days               INT,
        estimated_delivery_days     INT,
        delivery_delay_days         INT,
        return_status               NVARCHAR(50),
        return_reason               NVARCHAR(255),
        is_returned                 BIT,
        customer_rating             DECIMAL(3,1),
        review_sentiment            NVARCHAR(50),
        marketing_channel           NVARCHAR(100),
        campaign_name               NVARCHAR(100),
        coupon_code                 NVARCHAR(50),
        has_coupon                  BIT,
        loyalty_points_earned       INT,
        loyalty_points_redeemed     INT,
        quantity                    INT,
        gross_sales                 DECIMAL(12,2),
        discount_amount             DECIMAL(12,2),
        tax_amount                  DECIMAL(12,2),
        shipping_cost               DECIMAL(12,2),
        net_sales                   DECIMAL(12,2),
        product_cost                DECIMAL(12,2),
        profit                      DECIMAL(12,2),
        profit_margin_percentage    DECIMAL(7,2)
    );
END
GO

IF OBJECT_ID('gold.fact_order_items', 'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_order_items (
        order_item_key              INT IDENTITY (1,1) PRIMARY KEY,
        gold_created_at             DATETIME2 DEFAULT SYSDATETIME(),
        order_key                   INT,
        order_id                    NVARCHAR(50),
        date_key                    INT,
        customer_key                INT,
        product_key                 INT,
        quantity                    INT,
        unit_price                  DECIMAL(10,2),
        discount_percentage         DECIMAL(9,6),
        discount_amount             DECIMAL(12,2),
        gross_sales                 DECIMAL(12,2),
        tax_amount                  DECIMAL(12,2),
        shipping_cost               DECIMAL(12,2),
        net_sales                   DECIMAL(12,2),
        product_cost                DECIMAL(12,2),
        profit                      DECIMAL(12,2),
        is_quantity_corrected       BIT,
        is_net_sales_corrected      BIT
    );
END
GO


IF OBJECT_ID('gold.customer_summary', 'U') IS NULL
BEGIN
    CREATE TABLE gold.customer_summary (
        customer_key                INT PRIMARY KEY,
        gold_created_at             DATETIME2 DEFAULT SYSDATETIME(),
        customer_id                 NVARCHAR(50) NOT NULL UNIQUE,
        total_orders                INT,
        completed_orders            INT,
        cancelled_orders            INT,
        returned_orders             INT,
        return_rate_percentage      DECIMAL(5,2),
        total_quantity              INT,
        total_net_sales             DECIMAL(14,2),
        total_profit                DECIMAL(14,2),
        avg_order_value             DECIMAL(12,2),
        avg_customer_rating         DECIMAL(3,2),
        first_order_date            DATE,
        last_order_date             DATE,
        snapshot_date               DATE,
        days_since_last_order       INT,
        churn_threshold_days        INT,
        is_churned                  BIT
    );
END
GO
