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
        [CityKey] [int] NOT NULL,
        [WWICityID] [int] NOT NULL,
        [City] [nvarchar](50) NULL,
        [StateProvince] [nvarchar](50) NULL,
        [Location] [geography] NULL,
        [Country] [nvarchar](60) NULL,
        [Continent] [nvarchar](30) NULL,
        [SalesTerritory] [nvarchar](50) NULL,
        [Region] [nvarchar](30) NULL,
        [Subregion] [nvarchar](30) NULL,
        [LatestRecordedPopulation] [bigint] NULL,
        [LoadDate] [datetime2](7) NOT NULL
    )

	END;