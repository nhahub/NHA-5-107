USE RetailChurn;
GO

CREATE OR ALTER PROCEDURE staging.load_customers
    @FilePath NVARCHAR(MAX)
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
    DECLARE @SQL NVARCHAR(MAX);

    PRINT ''
    PRINT '================================================================';
    PRINT ' LOADING DATA INTO CUSTOMERS TABLE IN STAGING LAYER';
    PRINT '================================================================';
    
    SET @START_TIME = GETDATE();
    
    TRUNCATE TABLE staging.customers;

    SET @SQL = N'
    BULK INSERT staging.customers
    FROM ''' + REPLACE(@FilePath, '''', '''''') + '''
    WITH (
        FIRSTROW = 2,
        FORMAT = ''CSV'',
        FIELDQUOTE = ''"'',  
        CODEPAGE = ''65001'', 
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''\n'',
        TABLOCK);';

    EXEC sp_executesql @SQL;

    SET @END_TIME = GETDATE();
    PRINT ' > LOADED DATA INTO CUSTOMERS IN STAGING LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE staging.load_products
    @FilePath NVARCHAR(MAX)
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
    DECLARE @SQL NVARCHAR(MAX);

    PRINT ''
    PRINT '================================================================';
    PRINT ' LOADING DATA INTO PRODUCTS TABLE IN STAGING LAYER';
    PRINT '================================================================';
    
    SET @START_TIME = GETDATE();
    
    TRUNCATE TABLE staging.products;

    SET @SQL = N'
    BULK INSERT staging.products
    FROM ''' + REPLACE(@FilePath, '''', '''''') + '''
    WITH (
        FIRSTROW = 2,
        FORMAT = ''CSV'',
        FIELDQUOTE = ''"'',  
        CODEPAGE = ''65001'', 
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''\n'',
        TABLOCK);';

    EXEC sp_executesql @SQL;

    SET @END_TIME = GETDATE();
    PRINT ' > LOADED DATA INTO PRODUCTS IN STAGING LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE staging.load_order_items
    @FilePath NVARCHAR(MAX)
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
    DECLARE @SQL NVARCHAR(MAX);

    PRINT ''
    PRINT '================================================================';
    PRINT ' LOADING DATA INTO ORDER ITEMS TABLE IN STAGING LAYER';
    PRINT '================================================================';
    
    SET @START_TIME = GETDATE();
    
    TRUNCATE TABLE staging.order_items;

    SET @SQL = N'
    BULK INSERT staging.order_items
    FROM ''' + REPLACE(@FilePath, '''', '''''') + '''
    WITH (
        FIRSTROW = 2,
        FORMAT = ''CSV'',
        FIELDQUOTE = ''"'',  
        CODEPAGE = ''65001'', 
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''\n'',
        TABLOCK);';

    EXEC sp_executesql @SQL;

    SET @END_TIME = GETDATE();
    PRINT ' > LOADED DATA INTO ORDER ITEMS IN STAGING LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO

CREATE OR ALTER PROCEDURE staging.load_orders
    @FilePath NVARCHAR(MAX)
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
    DECLARE @SQL NVARCHAR(MAX);

    PRINT ''
    PRINT '================================================================';
    PRINT ' LOADING DATA INTO ORDERS TABLE IN STAGING LAYER';
    PRINT '================================================================';
    
    SET @START_TIME = GETDATE();
    
    TRUNCATE TABLE staging.orders;

    SET @SQL = N'
    BULK INSERT staging.orders
    FROM ''' + REPLACE(@FilePath, '''', '''''') + '''
    WITH (
        FIRSTROW = 2,
        FORMAT = ''CSV'',
        FIELDQUOTE = ''"'',  
        CODEPAGE = ''65001'', 
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''\n'',
        TABLOCK);';

    EXEC sp_executesql @SQL;

    SET @END_TIME = GETDATE();
    PRINT ' > LOADED DATA INTO ORDERS IN STAGING LAYER IN : ' + CAST(DATEDIFF(MILLISECOND, @START_TIME, @END_TIME) AS NVARCHAR(20)) + ' ms';
END;
GO