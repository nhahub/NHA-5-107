USE RetailChurn;
GO

IF OBJECT_ID('silver.customers', 'U') IS NULL
BEGIN
    CREATE TABLE silver.customers (
        silver_id                   INT IDENTITY (1,1) PRIMARY KEY,
        silver_created_at           DATETIME2 DEFAULT SYSDATETIME(),
        customer_id                 NVARCHAR(50) NOT NULL UNIQUE,
        customer_name               NVARCHAR(255),
        customer_age                INT,
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

IF OBJECT_ID('silver.products', 'U') IS NULL
BEGIN
    CREATE TABLE silver.products (
        silver_id                   INT IDENTITY (1,1) PRIMARY KEY,
        silver_created_at           DATETIME2 DEFAULT SYSDATETIME(),
        product_id                  NVARCHAR(50) NOT NULL UNIQUE,
        product_name                NVARCHAR(255),
        product_category            NVARCHAR(255),
        product_subcategory         NVARCHAR(255),
        product_brand               NVARCHAR(255),
        product_supplier            NVARCHAR(255),
        product_unit_price          DECIMAL(10,2),
        product_cost                DECIMAL(10,2),
        product_rating              DECIMAL(3,1)
    );
END
GO

IF OBJECT_ID('silver.order_items', 'U') IS NULL
BEGIN
    CREATE TABLE silver.order_items (
        silver_id                   INT IDENTITY (1,1) PRIMARY KEY,
        silver_created_at           DATETIME2 DEFAULT SYSDATETIME(),
        order_id                    NVARCHAR(50) NOT NULL,
        product_id                  NVARCHAR(50) NOT NULL,
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

IF OBJECT_ID('silver.orders', 'U') IS NULL
BEGIN
    CREATE TABLE silver.orders (
        silver_id                   INT IDENTITY (1,1) PRIMARY KEY,
        silver_created_at           DATETIME2 DEFAULT SYSDATETIME(),
        order_id                    NVARCHAR(50) NOT NULL UNIQUE,
        order_date                  DATE,
        order_time                  TIME(0),
        order_status                NVARCHAR(50),
        sales_channel               NVARCHAR(50),
        customer_id                 NVARCHAR(50),
        customer_type               NVARCHAR(50),
        payment_method              NVARCHAR(50),
        payment_status              NVARCHAR(50),
        currency                    NVARCHAR(10),
        shipping_method             NVARCHAR(50),
        warehouse                   NVARCHAR(50),
        delivery_days               INT,
        estimated_delivery_days     INT,
        delivery_status             NVARCHAR(50),
        return_status               NVARCHAR(50),
        return_reason               NVARCHAR(255),
        customer_rating             DECIMAL(3,1),
        review_sentiment            NVARCHAR(50),
        customer_review             NVARCHAR(255),
        marketing_channel           NVARCHAR(100),
        campaign_name               NVARCHAR(100),
        coupon_code                 NVARCHAR(50),
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
        profit_margin_percentage    DECIMAL(7,2),
        customer_lifetime_value     DECIMAL(12,2),
        is_repeat_customer          BIT,
        customer_order_count        INT
    );
END
GO
