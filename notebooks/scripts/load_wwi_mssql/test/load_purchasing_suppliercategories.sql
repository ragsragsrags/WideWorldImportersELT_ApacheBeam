SELECT
    [SupplierCategoryID],
    [SupplierCategoryName],
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
    SupplierCategoryID,
    ValidFrom,
    ValidTo

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY