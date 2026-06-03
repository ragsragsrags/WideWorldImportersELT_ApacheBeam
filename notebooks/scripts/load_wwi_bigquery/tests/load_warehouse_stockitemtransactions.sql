SELECT
    StockItemTransactionID,
    StockItemID,
    TransactionTypeID,
    CustomerID,
    InvoiceID,
    SupplierID,
    PurchaseOrderID,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', TransactionOccurredWhen) AS TransactionOccurredWhen,
    Quantity,
    LastEditedBy,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LastEditedWhen) AS LastEditedWhen,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LoadDate) AS LoadDate
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    StockItemTransactionID,
    LastEditedWhen

LIMIT << NumberOfRows >>;