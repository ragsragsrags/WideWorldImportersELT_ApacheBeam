SELECT
    CityID, 
    CityName, 
    StateProvinceID, 
    [Location] = CAST([Location] AS VARBINARY(MAX)), 
    LatestRecordedPopulation, 
    LastEditedBy, 
    ValidFrom, 
    ValidTo,
    LoadDate,
    NewColumn
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>' AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    CityID,
    ValidFrom,
    ValidTo

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY