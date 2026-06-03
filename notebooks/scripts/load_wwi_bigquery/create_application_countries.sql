CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
    CountryID INTEGER,
    CountryName STRING,
    FormalName STRING,
    IsoAlpha3Code STRING,
    IsoNumericCode INTEGER,
    CountryType STRING,
    LatestRecordedPopulation INTEGER,
    Continent STRING,
    Region STRING,
    Subregion STRING,
    Border STRING,
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