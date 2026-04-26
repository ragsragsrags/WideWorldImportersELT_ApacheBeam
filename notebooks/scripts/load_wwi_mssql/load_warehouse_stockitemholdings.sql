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
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(7))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    StockItemID,
    LastEditedWhen