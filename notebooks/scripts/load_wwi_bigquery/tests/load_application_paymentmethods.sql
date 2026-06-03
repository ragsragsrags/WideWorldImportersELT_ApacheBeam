SELECT
    PaymentMethodID,
    PaymentMethodName,
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
    PaymentMethodID,
    ValidFrom,
    ValidTo

LIMIT << NumberOfRows >>;