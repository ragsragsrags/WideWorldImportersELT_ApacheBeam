SELECT
    [CustomerCategoryID],
    [CustomerCategoryName],
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
    CustomerCategoryID,
    ValidFrom,
    ValidTo

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY