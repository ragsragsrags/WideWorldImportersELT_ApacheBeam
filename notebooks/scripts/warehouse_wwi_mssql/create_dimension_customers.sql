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
		[CustomerKey] [int] NOT NULL,
		[WWICustomerID] [int] NOT NULL,
		[WWIDeliveryCityID] [int] NOT NULL,
		[Customer] [nvarchar](100) NOT NULL,
		[BillToCustomer] [nvarchar](100) NOT NULL,
		[Category] [nvarchar](50) NOT NULL,
		[BuyingGroup] [nvarchar](50) NOT NULL,
		[PrimaryContact] [nvarchar](50) NOT NULL,
		[PostalCode] [nvarchar](10) NOT NULL,
		[LoadDate] [datetime2](7) NOT NULL,
		CONSTRAINT [PK_DimCustomer] PRIMARY KEY CLUSTERED 
		(
			[CustomerKey] ASC
		)
	)

	END

