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
        [StockHoldingKey] [bigint] NOT NULL,
        [StockItemKey] [int] NOT NULL,
        [QuantityOnHand] [int] NOT NULL,
        [BinLocation] [nvarchar](20) NOT NULL,
        [LastStocktakeQuantity] [int] NOT NULL,
        [LastCostPrice] [decimal](18, 2) NOT NULL,
        [ReorderLevel] [int] NOT NULL,
        [TargetStockLevel] [int] NOT NULL,
        [LoadDate] [datetime2](6) NOT NULL,
        [LastLoadDate] [datetime2](6) NULL,
        CONSTRAINT [PK_FctStockHoldings] PRIMARY KEY NONCLUSTERED 
        (
            [StockHoldingKey] ASC
        )
    )

    END;