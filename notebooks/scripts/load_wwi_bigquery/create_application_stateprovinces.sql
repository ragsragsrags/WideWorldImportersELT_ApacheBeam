CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>` 
(
	StateProvinceID INTEGER,
	StateProvinceCode STRING,
	StateProvinceName STRING,
	CountryID INTEGER,
	SalesTerritory STRING,
	Border STRING,
	LatestRecordedPopulation INTEGER,
	LastEditedBy INTEGER,
	ValidFrom DATETIME,
	ValidTo DATETIME,
	LoadDate DATETIME
);

DELETE 
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    LoadDate > (
		SELECT
			MAX(LoadDate)
		FROM
			`<< Database >>.<< LHSchema >>.<< LHTable >>`
		WHERE
			TableName = '<< TableName >>' AND
			Status = 'Successful'
	);