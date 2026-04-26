SELECT
    [StockItemTransactionID],
    [StockItemID],
    [TransactionTypeID],
    [CustomerID],
    [InvoiceID],
    [SupplierID],
    [PurchaseOrderID],
    [TransactionOccurredWhen],
    [Quantity],
    [LastEditedBy],
    [LastEditedWhen],
    [LoadDate]
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    StockItemTransactionID,
    LastEditedWhen

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY