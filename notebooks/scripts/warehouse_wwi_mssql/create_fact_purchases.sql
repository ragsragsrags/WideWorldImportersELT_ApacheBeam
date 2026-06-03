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
        [PurchaseKey] [bigint] NOT NULL,
        [DateKey] [date] NOT NULL,
        [SupplierKey] [int] NOT NULL,
        [StockItemKey] [int] NOT NULL,
        [WWIPurchaseOrderID] [int] NULL,
        [WWIPurchaseOrderLineID] [int] NULL,
        [OrderedOuters] [int] NOT NULL,
        [OrderedQuantity] [int] NOT NULL,
        [ReceivedOuters] [int] NOT NULL,
        [Package] [nvarchar](50) NOT NULL,
        [IsOrderFinalized] [bit] NOT NULL,
        [LoadDate] [datetime2](7) NOT NULL,
        CONSTRAINT [PK_Fact_Purchases] PRIMARY KEY NONCLUSTERED 
        (
            [PurchaseKey] ASC,
            [DateKey] ASC
        )
    ) 

    END;