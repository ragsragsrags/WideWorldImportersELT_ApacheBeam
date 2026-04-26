SELECT
    [StateProvinceID],
    [StateProvinceCode],
    [StateProvinceName],
    [CountryID],
    [SalesTerritory],
    [Border] = CAST([Border] AS VARBINARY(MAX)),
    [LatestRecordedPopulation],
    [LastEditedBy],
    [ValidFrom],
    [ValidTo],
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(7))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    StateProvinceID,
    ValidFrom,
    ValidTo