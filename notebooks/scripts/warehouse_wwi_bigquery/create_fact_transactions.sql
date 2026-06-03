CREATE TABLE IF NOT EXISTS << Database >>.<< Schema >>.<< Table >>
(
	TransactionKey INTEGER,
	DateKey DATE,
	CustomerKey INTEGER,
	BillToCustomerKey INTEGER,
	SupplierKey INTEGER,
	TransactionTypeKey INTEGER,
	PaymentMethodKey INTEGER,
	WWICustomerTransactionID INTEGER,
	WWISupplierTransactionID INTEGER,
	WWIInvoiceID INTEGER,
	WWIPurchaseOrderID INTEGER,
	SupplierInvoiceNumber STRING,
	TotalExcludingTax NUMERIC(18, 2),
	TaxAmount NUMERIC(18, 2),
	TotalIncludingTax NUMERIC(18, 2),
	OutstandingBalance NUMERIC(18, 2),
	IsFinalized BOOLEAN,
	LoadDate DATETIME
);