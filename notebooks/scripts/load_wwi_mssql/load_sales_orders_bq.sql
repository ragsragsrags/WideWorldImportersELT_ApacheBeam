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
    [PickingCompletedWhen] = LEFT(CONVERT(NVARCHAR, PickingCompletedWhen, 121), 26),
    [LastEditedBy],
    [LastEditedWhen] = LEFT(CONVERT(NVARCHAR, LastEditedWhen, 121), 26),
    [LoadDate] = LEFT(CONVERT(NVARCHAR, CAST('<< NewCutoffDate >>' AS DATETIME2(6)), 121), 26)
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    OrderID,
    LastEditedWhen

OFFSET 0 ROW