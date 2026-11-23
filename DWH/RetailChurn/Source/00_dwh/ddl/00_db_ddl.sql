USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'RetailChurn')
    CREATE DATABASE RetailChurn;
GO