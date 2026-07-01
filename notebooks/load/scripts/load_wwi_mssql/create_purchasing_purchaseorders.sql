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
		[PurchaseOrderID] [int] NOT NULL,
        [SupplierID] [int] NOT NULL,
        [OrderDate] [date] NOT NULL,
        [DeliveryMethodID] [int] NOT NULL,
        [ContactPersonID] [int] NOT NULL,
        [ExpectedDeliveryDate] [date] NULL,
        [SupplierReference] [nvarchar](20) NULL,
        [IsOrderFinalized] [bit] NOT NULL,
        [Comments] [nvarchar](max) NULL,
        [InternalComments] [nvarchar](max) NULL,
        [LastEditedBy] [int] NOT NULL,
        [LastEditedWhen] [datetime2](6) NOT NULL,
        [LoadDate] [datetime2](6) NOT NULL
	)

	END;