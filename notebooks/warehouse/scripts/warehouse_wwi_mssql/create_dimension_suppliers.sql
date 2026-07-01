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
        [SupplierKey] [int] NOT NULL,
        [WWISupplierID] [int] NOT NULL,
        [Supplier] [nvarchar](100) NOT NULL,
        [Category] [nvarchar](50) NOT NULL,
        [PrimaryContact] [nvarchar](50) NOT NULL,
        [SupplierReference] [nvarchar](20) NULL,
        [PaymentDays] [int] NOT NULL,
        [PostalCode] [nvarchar](10) NOT NULL,
        [LoadDate] [datetime2](6) NOT NULL,
        [LastLoadDate] [datetime2](6) NULL,
        CONSTRAINT [PK_DimSuppliers] PRIMARY KEY CLUSTERED 
        (
            [SupplierKey] ASC
        )
    ) 

    END;