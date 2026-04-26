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
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(7))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    StockItemTransactionID,
    LastEditedWhen