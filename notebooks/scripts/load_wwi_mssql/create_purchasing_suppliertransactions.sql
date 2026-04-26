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
		[SupplierTransactionID] [int] NOT NULL,
        [SupplierID] [int] NOT NULL,
        [TransactionTypeID] [int] NOT NULL,
        [PurchaseOrderID] [int] NULL,
        [PaymentMethodID] [int] NULL,
        [SupplierInvoiceNumber] [nvarchar](20) NULL,
        [TransactionDate] [date] NOT NULL,
        [AmountExcludingTax] [decimal](18, 2) NOT NULL,
        [TaxAmount] [decimal](18, 2) NOT NULL,
        [TransactionAmount] [decimal](18, 2) NOT NULL,
        [OutstandingBalance] [decimal](18, 2) NOT NULL,
        [FinalizationDate] [date] NULL,
        [IsFinalized] [bit],
        [LastEditedBy] [int] NOT NULL,
        [LastEditedWhen] [datetime2](7) NOT NULL,
        [LoadDate] [datetime2](7) NOT NULL
	)

	END