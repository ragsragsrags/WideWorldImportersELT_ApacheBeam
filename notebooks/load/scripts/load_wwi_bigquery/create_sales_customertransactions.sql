CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
    CustomerTransactionID INTEGER,
    CustomerID INTEGER,
    TransactionTypeID INTEGER,
    InvoiceID INTEGER,
    PaymentMethodID INTEGER,
    TransactionDate DATE,
    AmountExcludingTax NUMERIC(18, 2),
    TaxAmount NUMERIC(18, 2),
    TransactionAmount NUMERIC(18, 2),
    OutstandingBalance NUMERIC(18, 2),
    FinalizationDate DATE,
    IsFinalized  BOOLEAN,
    LastEditedBy INTEGER,
    LastEditedWhen DATETIME, 
    LoadDate DATETIME
);