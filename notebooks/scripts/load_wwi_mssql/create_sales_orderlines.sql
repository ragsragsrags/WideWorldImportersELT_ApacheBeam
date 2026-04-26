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
        [OrderLineID] [int] NOT NULL,
        [OrderID] [int] NOT NULL,
        [StockItemID] [int] NOT NULL,
        [Description] [nvarchar](100) NOT NULL,
        [PackageTypeID] [int] NOT NULL,
        [Quantity] [int] NOT NULL,
        [UnitPrice] [decimal](18, 2) NULL,
        [TaxRate] [decimal](18, 3) NOT NULL,
        [PickedQuantity] [int] NOT NULL,
        [PickingCompletedWhen] [datetime2](7) NULL,
        [LastEditedBy] [int] NOT NULL,
        [LastEditedWhen] [datetime2](7) NOT NULL,
		[LoadDate] DATETIME2(7) NOT NULL
    )

	END