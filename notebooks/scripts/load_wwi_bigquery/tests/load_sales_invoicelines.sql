SELECT
    InvoiceLineID,
    InvoiceID,
    StockItemID,
    Description,
    PackageTypeID,
    Quantity,
    UnitPrice,
    TaxRate,
    TaxAmount,
    LineProfit,
    ExtendedPrice,
    LastEditedBy,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LastEditedWhen) AS LastEditedWhen,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LoadDate) AS LoadDate
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    InvoiceID,
    InvoiceLineID,
    LastEditedWhen

LIMIT << NumberOfRows >>;