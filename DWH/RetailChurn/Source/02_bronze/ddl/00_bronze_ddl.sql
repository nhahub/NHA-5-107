USE RetailChurn;
GO

IF OBJECT_ID('bronze.customers', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.customers (
        bronze_id                   INT IDENTITY (1,1) PRIMARY KEY,
        bronze_created_at           DATETIME2 DEFAULT SYSDATETIME(),
        customer_id                 NVARCHAR(255),
        customer_name               NVARCHAR(255),
        customer_age                NVARCHAR(255),
        customer_gender             NVARCHAR(255),
        customer_segment            NVARCHAR(255),
        customer_city               NVARCHAR(255),
        customer_state              NVARCHAR(255),
        customer_country            NVARCHAR(255),
        customer_region             NVARCHAR(255),
        customer_postal_code        NVARCHAR(255),
        customer_acquisition_cost   NVARCHAR(255)
    );
END
GO

IF OBJECT_ID('bronze.products', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.products (
        bronze_id                   INT IDENTITY (1,1) PRIMARY KEY,
        bronze_created_at           DATETIME2 DEFAULT SYSDATETIME(),
        product_id                  NVARCHAR(255),
        product_name                NVARCHAR(255),
        product_category            NVARCHAR(255),
        product_subcategory         NVARCHAR(255),
        product_brand               NVARCHAR(255),
        product_supplier            NVARCHAR(255),
        product_unit_price          NVARCHAR(255),
        product_cost                NVARCHAR(255),
        product_rating              NVARCHAR(255)     
    );
END
GO

IF OBJECT_ID('bronze.order_items', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.order_items (
        bronze_id                   INT IDENTITY (1,1) PRIMARY KEY,
        bronze_created_at           DATETIME2 DEFAULT SYSDATETIME(),
        order_id                    NVARCHAR(255),
        product_id                  NVARCHAR(255),
        quantity                    NVARCHAR(255),
        unit_price                  NVARCHAR(255),
        discount_percentage         NVARCHAR(255),
        discount_amount             NVARCHAR(255),
        gross_sales                 NVARCHAR(255),
        tax_amount                  NVARCHAR(255),
        shipping_cost               NVARCHAR(255),
        net_sales                   NVARCHAR(255),
        product_cost                NVARCHAR(255),
        profit                      NVARCHAR(255)
    );
END
GO

IF OBJECT_ID('bronze.orders', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.orders (
        bronze_id                   INT IDENTITY (1,1) PRIMARY KEY,
        bronze_created_at           DATETIME2 DEFAULT SYSDATETIME(),
        order_id                    NVARCHAR(255),
        order_date                  NVARCHAR(255),
        order_time                  NVARCHAR(255),
        order_status                NVARCHAR(255),
        sales_channel               NVARCHAR(255),
        customer_id                 NVARCHAR(255),
        customer_name               NVARCHAR(255),
        customer_age                NVARCHAR(255),
        customer_gender             NVARCHAR(255),
        customer_segment            NVARCHAR(255),
        customer_type               NVARCHAR(255),
        customer_city               NVARCHAR(255),
        customer_state              NVARCHAR(255),
        customer_country            NVARCHAR(255),
        customer_region             NVARCHAR(255),
        customer_postal_code        NVARCHAR(255),
        payment_method              NVARCHAR(255),
        payment_status              NVARCHAR(255),
        currency                    NVARCHAR(255),
        shipping_method             NVARCHAR(255),
        warehouse                   NVARCHAR(255),
        delivery_days               NVARCHAR(255),
        estimated_delivery_days     NVARCHAR(255),
        delivery_status             NVARCHAR(255),
        return_status               NVARCHAR(255),
        return_reason               NVARCHAR(255),
        customer_rating             NVARCHAR(255),
        review_sentiment            NVARCHAR(255),
        customer_review             NVARCHAR(255),
        marketing_channel           NVARCHAR(255),
        campaign_name               NVARCHAR(255),
        coupon_code                 NVARCHAR(255),
        loyalty_points_earned       NVARCHAR(255),
        loyalty_points_redeemed     NVARCHAR(255),
        quantity                    NVARCHAR(255),
        gross_sales                 NVARCHAR(255),
        discount_amount             NVARCHAR(255),
        tax_amount                  NVARCHAR(255),
        shipping_cost               NVARCHAR(255),
        net_sales                   NVARCHAR(255),
        product_cost                NVARCHAR(255),
        profit                      NVARCHAR(255),
        profit_margin_percentage    NVARCHAR(255),
        customer_lifetime_value     NVARCHAR(255),
        is_repeat_customer          NVARCHAR(255),
        customer_order_count        NVARCHAR(255) 
    );
END
GO