SELECT
    [OrderLineID],
    [OrderID],
    [StockItemID],
    [Description],
    [PackageTypeID],
    [Quantity],
    [UnitPrice],
    [TaxRate],
    [PickedQuantity],
    [PickingCompletedWhen],
    [LastEditedBy],
    [LastEditedWhen], 
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(6))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    OrderID,
    OrderLineID,
    LastEditedWhen

OFFSET 0 ROW