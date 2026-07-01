SELECT
    [DeliveryMethodID],
    [DeliveryMethodName],
    [LastEditedBy],
    [ValidFrom],
    [ValidTo],
    LoadDate
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    DeliveryMethodID,
    ValidFrom,
    ValidTo

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY