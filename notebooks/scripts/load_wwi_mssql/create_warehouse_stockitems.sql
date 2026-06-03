IF NOT EXISTS 
(
	SELECT 
		1 
	FROM
		INFORMATION_SCHEMA.TABLES T  
	WHERE
		T.TABLE_CATALOG = '<< Database >>' AND
		T.TABLE_SCHEMA = '<< Schema >>' AND
		T.TABLE_NAME = '<< Table >>'
)
	BEGIN

    CREATE TABLE [<< Schema >>].[<< Table >>]
    (
        [StockItemID] [int] NOT NULL,
        [StockItemName] [nvarchar](100) NOT NULL,
        [SupplierID] [int] NOT NULL,
        [ColorID] [int] NULL,
        [UnitPackageID] [int] NOT NULL,
        [OuterPackageID] [int] NOT NULL,
        [Brand] [nvarchar](50) NULL,
        [Size] [nvarchar](20) NULL,
        [LeadTimeDays] [int] NOT NULL,
        [QuantityPerOuter] [int] NOT NULL,
        [IsChillerStock] [bit] NOT NULL,
        [Barcode] [nvarchar](50) NULL,
        [TaxRate] [decimal](18, 3) NOT NULL,
        [UnitPrice] [decimal](18, 2) NOT NULL,
        [RecommendedRetailPrice] [decimal](18, 2) NULL,
        [TypicalWeightPerUnit] [decimal](18, 3) NOT NULL,
        [MarketingComments] [nvarchar](max) NULL,
        [InternalComments] [nvarchar](max) NULL,
        [Photo] [varbinary](max) NULL,
        [CustomFields] [nvarchar](max) NULL,
        [Tags] [nvarchar](100) NULL,
        [SearchDetails] [nvarchar](max),
        [LastEditedBy] [int] NOT NULL,
        [ValidFrom] [datetime2](6) NOT NULL,
        [ValidTo] [datetime2](6) NOT NULL, 
		[LoadDate] DATETIME2(6) NOT NULL
    )

	END;

DELETE 
    [<< Schema >>].[<< Table >>] 
WHERE
    LoadDate > (
		SELECT
			MAX([LoadDate])
		FROM
			[<< LHSchema >>].[<< LHTable >>]
		WHERE
			[TableName] = '<< TableName >>' AND
			[Status] = 'Successful'
	);