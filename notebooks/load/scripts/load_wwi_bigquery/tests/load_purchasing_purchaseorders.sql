SELECT
    PurchaseOrderID,
    SupplierID,
    OrderDate,
    DeliveryMethodID,
    ContactPersonID,
    ExpectedDeliveryDate,
    SupplierReference,
    IsOrderFinalized,
    Comments,
    InternalComments,
    LastEditedBy,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LastEditedWhen) AS LastEditedWhen,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LoadDate) AS LoadDate
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    PurchaseOrderID,
    LastEditedWhen

LIMIT << NumberOfRows >>;