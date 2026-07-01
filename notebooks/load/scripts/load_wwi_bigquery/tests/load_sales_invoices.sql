SELECT
    InvoiceID,
    CustomerID,
    BillToCustomerID,
    OrderID,
    DeliveryMethodID,
    ContactPersonID,
    AccountsPersonID,
    SalespersonPersonID,
    PackedByPersonID,
    InvoiceDate,
    CustomerPurchaseOrderNumber,
    IsCreditNote,
    CreditNoteReason,
    Comments,
    DeliveryInstructions,
    InternalComments,
    TotalDryItems,
    TotalChillerItems,
    DeliveryRun,
    RunPosition,
    ReturnedDeliveryData,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', ConfirmedDeliveryTime) AS ConfirmedDeliveryTime,
    ConfirmedReceivedBy,
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
    LastEditedWhen

LIMIT << NumberOfRows >>;