SELECT
    [CustomerTransactionID],
    [CustomerID],
    [TransactionTypeID],
    [InvoiceID],
    [PaymentMethodID],
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
    CustomerTransactionID,
    LastEditedWhen

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY