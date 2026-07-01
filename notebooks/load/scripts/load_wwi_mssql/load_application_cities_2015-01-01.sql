SELECT
    CityID, 
    CityName, 
    StateProvinceID, 
    [Location] = CAST([Location] AS VARBINARY(MAX)), 
    LatestRecordedPopulation, 
    ValidFrom, 
    ValidTo,
    LoadDate = CAST('<< NewCutoffDate >>' AS DATETIME2(6)),
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
OFFSET 0 ROW