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
        [OrderID] [int] NOT NULL,
        [CustomerID] [int] NOT NULL,
        [SalespersonPersonID] [int] NOT NULL,
        [PickedByPersonID] [int] NULL,
        [ContactPersonID] [int] NOT NULL,
        [BackorderOrderID] [int] NULL,
        [OrderDate] [date] NOT NULL,
        [ExpectedDeliveryDate] [date] NOT NULL,
        [CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
        [IsUndersupplyBackordered] [bit] NOT NULL,
        [Comments] [nvarchar](max) NULL,
        [DeliveryInstructions] [nvarchar](max) NULL,
        [InternalComments] [nvarchar](max) NULL,
        [PickingCompletedWhen] [datetime2](7) NULL,
        [LastEditedBy] [int] NOT NULL,
        [LastEditedWhen] [datetime2](7) NOT NULL,
		[LoadDate] DATETIME2(7) NOT NULL
    )

	END