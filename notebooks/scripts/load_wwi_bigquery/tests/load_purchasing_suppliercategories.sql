SELECT
    SupplierCategoryID,
    SupplierCategoryName,
    LastEditedBy,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', ValidFrom) AS ValidFrom, 
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', ValidTo) AS ValidTo,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LoadDate) AS LoadDate
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    SupplierCategoryID,
    ValidFrom,
    ValidTo

LIMIT << NumberOfRows >>;