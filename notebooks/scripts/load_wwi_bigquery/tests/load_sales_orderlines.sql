SELECT
    OrderLineID,
    OrderID,
    StockItemID,
    Description,
    PackageTypeID,
    Quantity,
    UnitPrice,
    TaxRate,
    PickedQuantity,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', PickingCompletedWhen) AS PickingCompletedWhen,
    LastEditedBy,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LastEditedWhen) AS LastEditedWhen,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LoadDate) AS LoadDate
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    OrderID,
    OrderLineID,
    LastEditedWhen

LIMIT << NumberOfRows >>;