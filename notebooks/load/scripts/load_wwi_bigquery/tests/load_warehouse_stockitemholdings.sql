SELECT
    StockItemID,
    QuantityOnHand,
    BinLocation,
    LastStocktakeQuantity,
    LastCostPrice,
    ReorderLevel,
    TargetStockLevel,
    LastEditedBy,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LastEditedWhen) AS LastEditedWhen,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LoadDate) AS LoadDate
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    StockItemID,
    LastEditedWhen

LIMIT << NumberOfRows >>;