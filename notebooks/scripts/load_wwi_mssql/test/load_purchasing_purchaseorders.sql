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
    [LoadDate]
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    PurchaseOrderID,
    LastEditedWhen

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY