SELECT
    [PurchaseOrderID],
    [SupplierID],
    [OrderDate],
    [DeliveryMethodID],
    [ContactPersonID],
    [ExpectedDeliveryDate],
    [SupplierReference],
    [IsOrderFinalized],
    [Comments],
    [InternalComments],
    [LastEditedBy],
    [LastEditedWhen],
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(6))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    PurchaseOrderID,
    LastEditedWhen

OFFSET 0 ROW