SELECT
    [StockItemID],
    [QuantityOnHand],
    [BinLocation],
    [LastStocktakeQuantity],
    [LastCostPrice],
    [ReorderLevel],
    [TargetStockLevel],
    [LastEditedBy],
    [LastEditedWhen],
    [LoadDate]
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    StockItemID,
    LastEditedWhen

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY