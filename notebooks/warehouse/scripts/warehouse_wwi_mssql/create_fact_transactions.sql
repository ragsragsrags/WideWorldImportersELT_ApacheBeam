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
			[TransactionKey] [bigint] NOT NULL,
			[DateKey] [date] NOT NULL,
			[CustomerKey] [int] NULL,
			[BillToCustomerKey] [int] NULL,
			[SupplierKey] [int] NULL,
			[TransactionTypeKey] [int] NOT NULL,
			[PaymentMethodKey] [int] NULL,
			[WWICustomerTransactionID] [int] NULL,
			[WWISupplierTransactionID] [int] NULL,
			[WWIInvoiceID] [int] NULL,
			[WWIPurchaseOrderID] [int] NULL,
			[SupplierInvoiceNumber] [nvarchar](20) NULL,
			[TotalExcludingTax] [decimal](18, 2) NOT NULL,
			[TaxAmount] [decimal](18, 2) NOT NULL,
			[TotalIncludingTax] [decimal](18, 2) NOT NULL,
			[OutstandingBalance] [decimal](18, 2) NOT NULL,
			[IsFinalized] [bit] NOT NULL,
			[LoadDate] [datetime2](6) NOT NULL,
        	[LastLoadDate] [datetime2](6) NULL,
			CONSTRAINT [PK_FctTransaction] PRIMARY KEY NONCLUSTERED 
			(
				[TransactionKey] ASC,
				[DateKey] ASC
			)
		) 
    
    END;