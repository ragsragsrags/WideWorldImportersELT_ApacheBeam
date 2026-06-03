CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
    OrderLineID INTEGER,
    OrderID INTEGER,
    StockItemID INTEGER,
    Description STRING,
    PackageTypeID INTEGER,
    Quantity INTEGER,
    UnitPrice NUMERIC(18, 2),
    TaxRate NUMERIC(18, 3),
    PickedQuantity INTEGER,
    PickingCompletedWhen DATETIME,
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