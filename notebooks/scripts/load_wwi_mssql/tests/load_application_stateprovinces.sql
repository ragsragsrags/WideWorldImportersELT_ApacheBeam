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
    [LoadDate]
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    StateProvinceID,
    ValidFrom,
    ValidTo

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY