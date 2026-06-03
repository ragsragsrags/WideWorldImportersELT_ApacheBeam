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
        [CountryID] INT NOT NULL,
        [CountryName] NVARCHAR(60) NOT NULL,
        [FormalName] NVARCHAR(60) NOT NULL,
        [IsoAlpha3Code] NVARCHAR(3) NULL,
        [IsoNumericCode] INT NULL,
        [CountryType] NVARCHAR(30) NULL,
        [LatestRecordedPopulation] BIGINT NULL,
        [Continent] NVARCHAR(30) NOT NULL,
        [Region] NVARCHAR(30) NOT NULL,
        [Subregion] NVARCHAR(30) NOT NULL,
        [Border] GEOGRAPHY NULL,
        [LastEditedBy] INT NOT NULL,
        [ValidFrom] DATETIME2(6) NOT NULL,
        [ValidTo] DATETIME2(6) NOT NULL, 
		[LoadDate] DATETIME2(6) NOT NULL
    )

	END;

DELETE 
    [<< Schema >>].[<< Table >>] 
WHERE
    LoadDate > (
		SELECT
			MAX([LoadDate])
		FROM
			[<< LHSchema >>].[<< LHTable >>]
		WHERE
			[TableName] = '<< TableName >>' AND
			[Status] = 'Successful'
	);