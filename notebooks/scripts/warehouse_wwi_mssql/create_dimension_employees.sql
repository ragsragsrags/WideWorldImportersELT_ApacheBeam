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
        [EmployeeKey] [int] NOT NULL,
        [WWIEmployeeID] [int] NOT NULL,
        [Employee] [nvarchar](50) NOT NULL,
        [PreferredName] [nvarchar](50) NOT NULL,
        [IsSalesperson] [bit] NOT NULL,
        [Photo] [varbinary](max) NULL,
        [LoadDate] [datetime2](7) NOT NULL,
        CONSTRAINT [PK_DimEmployee] PRIMARY KEY CLUSTERED 
        (
            [EmployeeKey] ASC
        )
    )

    END