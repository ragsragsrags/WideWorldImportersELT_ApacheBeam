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
        [StockItemTransactionID] [int] NOT NULL,
        [StockItemID] [int] NOT NULL,
        [TransactionTypeID] [int] NOT NULL,
        [CustomerID] [int] NULL,
        [InvoiceID] [int] NULL,
        [SupplierID] [int] NULL,
        [PurchaseOrderID] [int] NULL,
        [TransactionOccurredWhen] [datetime2](6) NOT NULL,
        [Quantity] [decimal](18, 3) NOT NULL,
        [LastEditedBy] [int] NOT NULL,
        [LastEditedWhen] [datetime2](6) NOT NULL,
		[LoadDate] DATETIME2(6) NOT NULL
    )

	END;