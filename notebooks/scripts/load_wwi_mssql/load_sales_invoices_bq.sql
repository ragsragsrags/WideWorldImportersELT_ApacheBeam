SELECT
    [InvoiceID],
    [CustomerID],
    [BillToCustomerID],
    [OrderID],
    [DeliveryMethodID],
    [ContactPersonID],
    [AccountsPersonID],
    [SalespersonPersonID],
    [PackedByPersonID],
    [InvoiceDate],
    [CustomerPurchaseOrderNumber],
    [IsCreditNote],
    [CreditNoteReason],
    [Comments],
    [DeliveryInstructions],
    [InternalComments],
    [TotalDryItems],
    [TotalChillerItems],
    [DeliveryRun],
    [RunPosition],
    [ReturnedDeliveryData],
    [ConfirmedDeliveryTime] = LEFT(CONVERT(NVARCHAR, ConfirmedDeliveryTime, 121), 26),
    [ConfirmedReceivedBy],
    [LastEditedBy],
    [LastEditedWhen] = LEFT(CONVERT(NVARCHAR, LastEditedWhen, 121), 26),
    [LoadDate] = LEFT(CONVERT(NVARCHAR, CAST('<< NewCutoffDate >>' AS DATETIME2(6)), 121), 26)
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    InvoiceID,
    LastEditedWhen

OFFSET 0 ROW