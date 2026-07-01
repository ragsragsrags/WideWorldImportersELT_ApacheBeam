CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
	PurchaseOrderLineID INTEGER,
	PurchaseOrderID INTEGER,
	StockItemID INTEGER,
	OrderedOuters INTEGER,
	Description STRING,
	ReceivedOuters INTEGER,
	PackageTypeID INTEGER,
	ExpectedUnitPricePerOuter NUMERIC(18, 2),
	LastReceiptDate DATE,
	IsOrderLineFinalized BOOLEAN,
	LastEditedBy INTEGER,
	LastEditedWhen DATETIME,
	LoadDate DATETIME
);