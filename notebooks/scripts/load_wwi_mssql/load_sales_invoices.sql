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
    [ConfirmedDeliveryTime],
    [ConfirmedReceivedBy],
    [LastEditedBy],
    [LastEditedWhen], 
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(7))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    InvoiceID,
    LastEditedWhen