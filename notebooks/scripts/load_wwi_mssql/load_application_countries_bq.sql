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
    [Border] = Border.STAsText(),
    [LastEditedBy],
    [ValidFrom] = LEFT(CONVERT(NVARCHAR, ValidFrom, 121), 26), 
    [ValidTo] = LEFT(CONVERT(NVARCHAR, ValidTo, 121), 26),
    [LoadDate] = LEFT(CONVERT(NVARCHAR, CAST('<< NewCutoffDate >>' AS DATETIME2(6)), 121), 26)
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