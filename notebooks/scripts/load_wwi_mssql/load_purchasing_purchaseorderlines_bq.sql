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
    [LastEditedWhen] = LEFT(CONVERT(NVARCHAR, LastEditedWhen, 121), 26),
    [LoadDate] = LEFT(CONVERT(NVARCHAR, CAST('<< NewCutoffDate >>' AS DATETIME2(6)), 121), 26)
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