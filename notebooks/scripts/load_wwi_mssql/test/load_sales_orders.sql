SELECT
    [OrderID],
    [CustomerID],
    [SalespersonPersonID],
    [PickedByPersonID],
    [ContactPersonID],
    [BackorderOrderID],
    [OrderDate],
    [ExpectedDeliveryDate],
    [CustomerPurchaseOrderNumber],
    [IsUndersupplyBackordered],
    [Comments],
    [DeliveryInstructions],
    [InternalComments],
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
    LastEditedWhen

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY