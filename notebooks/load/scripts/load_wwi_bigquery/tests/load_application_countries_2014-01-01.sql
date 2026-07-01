SELECT
    CountryID,
    CountryName,
    FormalName,
    IsoAlpha3Code,
    IsoNumericCode,
    CountryType,
    LatestRecordedPopulation,
    Continent,
    Region,
    Subregion,
    Border,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', ValidFrom) AS ValidFrom, 
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', ValidTo) AS ValidTo,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LoadDate) AS LoadDate
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    CountryID,
    ValidFrom,
    ValidTo

LIMIT << NumberOfRows >>;