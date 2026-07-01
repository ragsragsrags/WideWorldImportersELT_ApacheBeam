SELECT
    [InvoiceLineID],
    [InvoiceID],
    [StockItemID],
    [Description],
    [PackageTypeID],
    [Quantity],
    [UnitPrice],
    [TaxRate],
    [TaxAmount],
    [LineProfit],
    [ExtendedPrice],
    [LastEditedBy],
    [LastEditedWhen], 
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(6))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    InvoiceID,
    InvoiceLineID,
    LastEditedWhen

OFFSET 0 ROW