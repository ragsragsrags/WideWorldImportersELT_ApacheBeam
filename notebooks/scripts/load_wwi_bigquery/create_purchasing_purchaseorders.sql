CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
	PurchaseOrderID INTEGER,
	SupplierID INTEGER,
	OrderDate DATE,
	DeliveryMethodID INTEGER,
	ContactPersonID INTEGER,
	ExpectedDeliveryDate DATE,
	SupplierReference STRING,
	IsOrderFinalized BOOLEAN,
	Comments STRING,
	InternalComments STRING,
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