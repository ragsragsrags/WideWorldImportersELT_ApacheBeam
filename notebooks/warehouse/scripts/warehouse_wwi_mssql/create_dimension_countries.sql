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
        [CountryKey] [int] NOT NULL,
        [WWICountryID] [int] NOT NULL,
        [Country] [nvarchar](60) NOT NULL,
        [LoadDate] [datetime2](6) NOT NULL,
        [LastLoadDate] [datetime2](6) NULL
    )

	END;