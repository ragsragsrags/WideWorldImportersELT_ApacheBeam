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
        [OrderKey] [bigint] NOT NULL,
        [CityKey] [int] NOT NULL,
        [CustomerKey] [int] NOT NULL,
        [StockItemKey] [int] NOT NULL,
        [OrderDateKey] [date] NOT NULL,
        [PickedDateKey] [date] NULL,
        [SalesPersonKey] [int] NOT NULL,
        [PickerKey] [int] NULL,
        [WWIOrderID] [int] NOT NULL,
        [WWIOrderLineID] [int] NOT NULL,
        [WWIBackorderID] [int] NULL,
        [Description] [nvarchar](100) NOT NULL,
        [Package] [nvarchar](50) NOT NULL,
        [Quantity] [int] NOT NULL,
        [UnitPrice] [decimal](18, 2) NOT NULL,
        [TaxRate] [decimal](18, 3) NOT NULL,
        [TotalExcludingTax] [decimal](18, 2) NOT NULL,
        [TaxAmount] [decimal](18, 2) NOT NULL,
        [TotalIncludingTax] [decimal](18, 2) NOT NULL,
        [LoadDate] [datetime] NOT NULL,
        CONSTRAINT [PK_FctOrders] PRIMARY KEY NONCLUSTERED 
        (
            [OrderKey] ASC,
            [OrderDateKey] ASC
        )
    ) 

    END