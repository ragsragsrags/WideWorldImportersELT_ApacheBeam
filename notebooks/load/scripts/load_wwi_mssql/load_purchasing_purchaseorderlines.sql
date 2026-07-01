SELECT
    [PurchaseOrderLineID],
    [PurchaseOrderID],
    [StockItemID],
    [OrderedOuters],
    [Description],
    [ReceivedOuters],
    [PackageTypeID],
    [ExpectedUnitPricePerOuter],
    [LastReceiptDate],
    [IsOrderLineFinalized],
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
    PurchaseOrderLineID,
    LastEditedWhen

OFFSET 0 ROW