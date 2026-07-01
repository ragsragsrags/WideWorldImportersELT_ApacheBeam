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
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(6))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    StockItemID,
    LastEditedWhen

OFFSET 0 ROW