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
        [InvoiceID] [int] NOT NULL,
        [CustomerID] [int] NOT NULL,
        [BillToCustomerID] [int] NOT NULL,
        [OrderID] [int] NULL,
        [DeliveryMethodID] [int] NOT NULL,
        [ContactPersonID] [int] NOT NULL,
        [AccountsPersonID] [int] NOT NULL,
        [SalespersonPersonID] [int] NOT NULL,
        [PackedByPersonID] [int] NOT NULL,
        [InvoiceDate] [date] NOT NULL,
        [CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
        [IsCreditNote] [bit] NOT NULL,
        [CreditNoteReason] [nvarchar](max) NULL,
        [Comments] [nvarchar](max) NULL,
        [DeliveryInstructions] [nvarchar](max) NULL,
        [InternalComments] [nvarchar](max) NULL,
        [TotalDryItems] [int] NOT NULL,
        [TotalChillerItems] [int] NOT NULL,
        [DeliveryRun] [nvarchar](5) NULL,
        [RunPosition] [nvarchar](5) NULL,
        [ReturnedDeliveryData] [nvarchar](max) NULL,
        [ConfirmedDeliveryTime]  [datetime2](6),
        [ConfirmedReceivedBy] [nvarchar](50),
        [LastEditedBy] [int] NOT NULL,
        [LastEditedWhen] [datetime2](6) NOT NULL, 
		[LoadDate] DATETIME2(6) NOT NULL
    )

	END;