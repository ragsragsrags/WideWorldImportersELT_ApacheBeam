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
    [LoadDate]
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    OrderID,
    OrderLineID,
    LastEditedWhen

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY