SELECT
    [StockItemID],
    [QuantityOnHand],
    [BinLocation],
    [LastStocktakeQuantity],
    [LastCostPrice],
    [ReorderLevel],
    [TargetStockLevel],
    [LastEditedBy],
    [LastEditedWhen] = LEFT(CONVERT(NVARCHAR, LastEditedWhen, 121), 26),
    [LoadDate] = LEFT(CONVERT(NVARCHAR, CAST('<< NewCutoffDate >>' AS DATETIME2(6)), 121), 26)
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    StockItemID,
    LastEditedWhen

OFFSET 0 ROW