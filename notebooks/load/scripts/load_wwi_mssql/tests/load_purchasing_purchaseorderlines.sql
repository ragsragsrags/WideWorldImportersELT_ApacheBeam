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
    [LoadDate]
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    PurchaseOrderID,
    PurchaseOrderLineID,
    LastEditedWhen

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY