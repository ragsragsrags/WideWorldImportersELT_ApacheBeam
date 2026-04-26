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
		CityID INT, 
		CityName NVARCHAR(50), 
		StateProvinceID INT, 
		[Location] GEOGRAPHY, 
		LatestRecordedPopulation BIGINT, 
		LastEditedBy INT, 
		ValidFrom DATETIME2(7) NOT NULL, 
		ValidTo DATETIME2(7) NOT NULL, 
		LoadDate DATETIME2(7) NOT NULL
	)

	END