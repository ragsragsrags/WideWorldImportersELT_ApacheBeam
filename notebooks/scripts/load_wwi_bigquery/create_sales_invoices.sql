CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
   InvoiceID INTEGER,
   CustomerID INTEGER,
   BillToCustomerID INTEGER,
   OrderID INTEGER,
   DeliveryMethodID INTEGER,
   ContactPersonID INTEGER,
   AccountsPersonID INTEGER,
   SalespersonPersonID INTEGER,
   PackedByPersonID INTEGER,
   InvoiceDate DATE,
   CustomerPurchaseOrderNumber STRING,
   IsCreditNote BOOLEAN,
   CreditNoteReason STRING,
   Comments STRING,
   DeliveryInstructions STRING,
   InternalComments STRING,
   TotalDryItems INTEGER,
   TotalChillerItems INTEGER,
   DeliveryRun STRING,
   RunPosition STRING,
   ReturnedDeliveryData STRING,
   ConfirmedDeliveryTime  DATETIME,
   ConfirmedReceivedBy STRING,
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