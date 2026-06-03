SELECT
    CustomerTransactionID,
    CustomerID,
    TransactionTypeID,
    InvoiceID,
    PaymentMethodID,
    TransactionDate,
    AmountExcludingTax,
    TaxAmount,
    TransactionAmount,
    OutstandingBalance,
    FinalizationDate,
    IsFinalized,
    LastEditedBy,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LastEditedWhen) AS LastEditedWhen,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LoadDate) AS LoadDate
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    CustomerTransactionID,
    LastEditedWhen

LIMIT << NumberOfRows >>;