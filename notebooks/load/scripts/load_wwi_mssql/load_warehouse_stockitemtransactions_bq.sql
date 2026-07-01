SELECT
    [StockItemTransactionID],
    [StockItemID],
    [TransactionTypeID],
    [CustomerID],
    [InvoiceID],
    [SupplierID],
    [PurchaseOrderID],
    [TransactionOccurredWhen] = LEFT(CONVERT(NVARCHAR, TransactionOccurredWhen, 121), 26),
    [Quantity],
    [LastEditedBy],
    [LastEditedWhen] = LEFT(CONVERT(NVARCHAR, LastEditedWhen, 121), 26),
    [LoadDate] = LEFT(CONVERT(NVARCHAR, CAST('<< NewCutoffDate >>' AS DATETIME2(6)), 121), 26)
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    StockItemTransactionID,
    LastEditedWhen

OFFSET 0 ROW