SELECT
    [StockItemStockGroupID],
    [StockItemID],
    [StockGroupID],
    [LastEditedBy],
    [LastEditedWhen],
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(6))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    StockItemStockGroupID,
    LastEditedWhen

OFFSET 0 ROW