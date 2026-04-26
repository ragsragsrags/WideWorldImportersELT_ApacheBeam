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
        [StateProvinceID] [int] NOT NULL,
        [StateProvinceCode] [nvarchar](5) NOT NULL,
        [StateProvinceName] [nvarchar](50) NOT NULL,
        [CountryID] [int] NOT NULL,
        [SalesTerritory] [nvarchar](50) NOT NULL,
        [Border] [geography] NULL,
        [LatestRecordedPopulation] [bigint] NULL,
        [LastEditedBy] [int] NOT NULL,
        [ValidFrom] [datetime2](7) NOT NULL,
        [ValidTo] [datetime2](7) NOT NULL,
        [LoadDate] [datetime2](7) NOT NULL
	)

	END