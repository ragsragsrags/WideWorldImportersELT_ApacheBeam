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
        [TransactionTypeKey] [int] NOT NULL,
        [WWITransactionTypeID] [int] NOT NULL,
        [TransactionType] [nvarchar](50) NOT NULL,
        [LoadDate] [datetime2](6) NOT NULL,
        [LastLoadDate] [datetime2](6) NULL,
        CONSTRAINT [PK_DimTransactionTypes] PRIMARY KEY CLUSTERED 
        (
            [TransactionTypeKey] ASC
        )
    ) 

    END;