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
    [LastEditedWhen] = LEFT(CONVERT(NVARCHAR, LastEditedWhen, 121), 26),
    [LoadDate] = LEFT(CONVERT(NVARCHAR, CAST('<< NewCutoffDate >>' AS DATETIME2(6)), 121), 26)
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    PurchaseOrderID,
    LastEditedWhen

OFFSET 0 ROW