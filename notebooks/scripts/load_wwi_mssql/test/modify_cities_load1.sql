SELECT
    CityID,
    NewColumn,
    ValidFrom,
    ValidTo
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom <= '<< LastCutoffDate >>' 
ORDER BY 
    CityID,
    ValidFrom,
    ValidTo

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY