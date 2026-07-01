SELECT
    [DeliveryMethodID],
    [DeliveryMethodName],
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
    DeliveryMethodID,
    ValidFrom,
    ValidTo
    
OFFSET 0 ROW