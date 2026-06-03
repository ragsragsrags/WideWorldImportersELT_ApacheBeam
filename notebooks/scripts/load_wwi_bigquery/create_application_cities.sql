CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
    CityID INTEGER, 
    CityName STRING, 
    StateProvinceID INTEGER, 
    Location STRING, 
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