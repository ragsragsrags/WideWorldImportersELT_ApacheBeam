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
    [LastEditedWhen],
    [LoadDate]
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    SupplierTransactionID,
    LastEditedWhen

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY