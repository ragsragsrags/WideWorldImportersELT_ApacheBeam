SELECT
    [SupplierTransactionID],
    [SupplierID],
    [TransactionTypeID],
    [PurchaseOrderID],
    [PaymentMethodID],
    [SupplierInvoiceNumber],
    [TransactionDate],
    [AmountExcludingTax],
    [TaxAmount],
    [TransactionAmount],
    [OutstandingBalance],
    [FinalizationDate],
    [IsFinalized],
    [LastEditedBy],
    [LastEditedWhen] = LEFT(CONVERT(NVARCHAR, LastEditedWhen, 121), 26),
    [LoadDate] = LEFT(CONVERT(NVARCHAR, CAST('<< NewCutoffDate >>' AS DATETIME2(6)), 121), 26)
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    SupplierTransactionID,
    LastEditedWhen

OFFSET 0 ROW