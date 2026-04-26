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
		[PurchaseOrderLineID] [int] NOT NULL,
        [PurchaseOrderID] [int] NOT NULL,
        [StockItemID] [int] NOT NULL,
        [OrderedOuters] [int] NOT NULL,
        [Description] [nvarchar](100) NOT NULL,
        [ReceivedOuters] [int] NOT NULL,
        [PackageTypeID] [int] NOT NULL,
        [ExpectedUnitPricePerOuter] [decimal](18, 2) NULL,
        [LastReceiptDate] [date] NULL,
        [IsOrderLineFinalized] [bit] NOT NULL,
        [LastEditedBy] [int] NOT NULL,
        [LastEditedWhen] [datetime2](7) NOT NULL,
        [LoadDate] [datetime2](7) NOT NULL
	)

	END