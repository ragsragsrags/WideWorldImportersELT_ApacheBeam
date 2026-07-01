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
        [PaymentMethodKey] [int] NOT NULL,
        [WWIPaymentMethodID] [int] NOT NULL,
        [PaymentMethod] [nvarchar](50) NOT NULL,
        [LoadDate] [datetime2](6) NOT NULL,
        [LastLoadDate] [datetime2](6) NULL,
        CONSTRAINT [PK_DimPaymentMethod] PRIMARY KEY CLUSTERED 
        (
            [PaymentMethodKey] ASC
        )
    ) 

    END;