SELECT 
    CityID, 
    CityName, 
    StateProvinceID, 
    [Location] = CAST([Location] AS VARBINARY(MAX)), 
    LatestRecordedPopulation, 
    LastEditedBy, 
    ValidFrom, 
    ValidTo,
    LoadDate = CAST('<< NewCutoffDate >>' AS DATETIME2(7))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>' AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    CityID,
    ValidFrom,
    ValidTo