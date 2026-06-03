SELECT
    CityID,
    NewColumn,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', ValidFrom) AS ValidFrom, 
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', ValidTo) AS ValidTo
FROM
    << Database >>.<< Schema >>.<< Table >>
WHERE
    ValidFrom <= '<< LastCutoffDate >>' 
ORDER BY 
    CityID,
    ValidFrom,
    ValidTo

LIMIT << NumberOfRows >>;