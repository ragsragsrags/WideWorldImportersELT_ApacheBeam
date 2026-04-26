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
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(7))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    OrderID,
    LastEditedWhen