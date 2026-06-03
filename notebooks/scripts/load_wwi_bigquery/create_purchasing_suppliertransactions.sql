CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
    SupplierTransactionID INTEGER,
    SupplierID INTEGER,
    TransactionTypeID INTEGER,
    PurchaseOrderID INTEGER,
    PaymentMethodID INTEGER,
    SupplierInvoiceNumber STRING,
    TransactionDate DATE,
    AmountExcludingTax NUMERIC(18, 2),
    TaxAmount NUMERIC(18, 2),
    TransactionAmount NUMERIC(18, 2),
    OutstandingBalance NUMERIC(18, 2),
    FinalizationDate DATE,
    IsFinalized BOOLEAN,
    LastEditedBy INTEGER,
    LastEditedWhen DATETIME,
    LoadDate DATETIME
);

DELETE 
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    LoadDate > (
		SELECT
			MAX(LoadDate)
		FROM
			`<< Database >>.<< LHSchema >>.<< LHTable >>`
		WHERE
			TableName = '<< TableName >>' AND
			Status = 'Successful'
	);