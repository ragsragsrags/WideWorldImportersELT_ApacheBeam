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
        [SaleKey] [bigint] NOT NULL,
        [CityKey] [int] NOT NULL,
        [CustomerKey] [int] NOT NULL,
        [BillToCustomerKey] [int] NOT NULL,
        [StockItemKey] [int] NOT NULL,
        [InvoiceDateKey] [date] NOT NULL,
        [DeliveryDateKey] [date] NULL,
        [SalespersonKey] [int] NOT NULL,
        [WWIInvoiceID] [int] NOT NULL,
        [WWIInvoiceLineID] [int] NOT NULL,
        [Description] [nvarchar](100) NOT NULL,
        [Package] [nvarchar](50) NOT NULL,
        [Quantity] [int] NOT NULL,
        [UnitPrice] [decimal](18, 2) NOT NULL,
        [TaxRate] [decimal](18, 3) NOT NULL,
        [TotalExcludingTax] [decimal](18, 2) NOT NULL,
        [TaxAmount] [decimal](18, 2) NOT NULL,
        [Profit] [decimal](18, 2) NOT NULL,
        [TotalIncludingTax] [decimal](18, 2) NOT NULL,
        [TotalDryItems] [int] NOT NULL,
        [TotalChillerItems] [int] NOT NULL,
        [LoadDate] [datetime2](6) NOT NULL,
        [LastLoadDate] [datetime2](6) NULL,
        CONSTRAINT [PK_FctSale] PRIMARY KEY NONCLUSTERED 
        (
            [SaleKey] ASC,
            [InvoiceDateKey] ASC
        )
    )

    END;