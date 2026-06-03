CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
    StockItemTransactionID INTEGER,
    StockItemID INTEGER,
    TransactionTypeID INTEGER,
    CustomerID INTEGER,
    InvoiceID INTEGER,
    SupplierID INTEGER,
    PurchaseOrderID INTEGER,
    TransactionOccurredWhen DATETIME,
    Quantity NUMERIC(18, 3),
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