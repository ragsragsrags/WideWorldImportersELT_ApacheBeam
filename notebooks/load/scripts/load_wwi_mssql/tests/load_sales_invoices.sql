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
    [LoadDate]
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    InvoiceID,
    LastEditedWhen

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY