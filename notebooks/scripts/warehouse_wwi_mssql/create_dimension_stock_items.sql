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
        [StockItemKey] [int] NOT NULL,
        [WWIStockItemID] [int] NOT NULL,
        [StockItem] [nvarchar](100) NOT NULL,
        [Color] [nvarchar](20) NOT NULL,
        [SellingPackage] [nvarchar](50) NOT NULL,
        [BuyingPackage] [nvarchar](50) NOT NULL,
        [Brand] [nvarchar](50) NOT NULL,
        [Size] [nvarchar](20) NOT NULL,
        [LeadTimeDays] [int] NOT NULL,
        [QuantityPerOuter] [int] NOT NULL,
        [IsChillerStock] [int] NOT NULL,
        [Barcode] [nvarchar](50) NULL,
        [TaxRate] [decimal](18, 3) NOT NULL,
        [UnitPrice] [decimal](18, 2) NOT NULL,
        [RecommendedRetailPrice] [decimal](18, 2) NULL,
        [TypicalWeightPerUnit] [decimal](18, 3) NOT NULL,
        [Photo] [varbinary](max) NULL,
        [LoadDate] [datetime2](7) NOT NULL,
        CONSTRAINT [PK_DimStockItems] PRIMARY KEY CLUSTERED 
        (
            [StockItemKey] ASC
        )	
    )

    END