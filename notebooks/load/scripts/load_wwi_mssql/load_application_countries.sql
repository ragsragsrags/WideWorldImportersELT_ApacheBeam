SELECT
    [CountryID],
    [CountryName],
    [FormalName],
    [IsoAlpha3Code],
    [IsoNumericCode],
    [CountryType],
    [LatestRecordedPopulation],
    [Continent],
    [Region],
    [Subregion],
    [Border] = CAST([Border] AS VARBINARY(MAX)),
    [LastEditedBy],
    [ValidFrom],
    [ValidTo],
    LoadDate = CAST('<< NewCutoffDate >>' AS DATETIME2(6))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    CountryID,
    ValidFrom,
    ValidTo
    
OFFSET 0 ROW