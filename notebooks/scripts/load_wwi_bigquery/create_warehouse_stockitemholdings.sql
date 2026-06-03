CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
    StockItemID INTEGER,
    QuantityOnHand INTEGER,
    BinLocation STRING,
    LastStocktakeQuantity INTEGER,
    LastCostPrice NUMERIC(18, 2),
    ReorderLevel INTEGER,
    TargetStockLevel INTEGER,
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