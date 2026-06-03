SELECT
    [SupplierCategoryID],
    [SupplierCategoryName],
    [LastEditedBy],
    [ValidFrom],
    [ValidTo],
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(6))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    SupplierCategoryID,
    ValidFrom,
    ValidTo

OFFSET 0 ROW