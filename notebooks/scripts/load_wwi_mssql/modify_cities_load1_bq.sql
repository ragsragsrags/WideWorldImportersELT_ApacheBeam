SELECT
    CityID,
    NewColumn,
    ValidFrom = LEFT(CONVERT(NVARCHAR, ValidFrom, 121), 26), 
    ValidTo = LEFT(CONVERT(NVARCHAR, ValidTo, 121), 26)
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom <= '<< LastCutoffDate >>' 
ORDER BY
    CityID,
    ValidFrom,
    ValidTo
OFFSET 0 ROW