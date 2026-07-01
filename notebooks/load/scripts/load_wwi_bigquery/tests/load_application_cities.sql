SELECT
    CityID, 
    CityName, 
    StateProvinceID, 
    Location, 
    LatestRecordedPopulation, 
    LastEditedBy, 
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', ValidFrom) AS ValidFrom, 
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', ValidTo) AS ValidTo,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LoadDate) AS LoadDate,
    NewColumn
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    ValidFrom > '<< LastCutoffDate >>' AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    CityID,
    ValidFrom,
    ValidTo

LIMIT << NumberOfRows >>;