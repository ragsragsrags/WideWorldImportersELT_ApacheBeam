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
        [MovementKey] [int] NOT NULL,
        [DateKey] [date] NOT NULL,
        [StockItemKey] [int] NOT NULL,
        [CustomerKey] [int] NULL,
        [SupplierKey] [int] NULL,
        [TransactionTypeKey] [int] NOT NULL,
        [WWIStockItemTransactionID] [int] NOT NULL,
        [WWIInvoiceID] [int] NULL,
        [WWIPurchaseOrderID] [int] NULL,
        [Quantity] [int] NOT NULL,
        [LoadDate] [datetime2](7) NOT NULL,
        CONSTRAINT [PK_FctMovement] PRIMARY KEY CLUSTERED 
        (
            [MovementKey] ASC,
            [DateKey] ASC
        )
    ) 

    END