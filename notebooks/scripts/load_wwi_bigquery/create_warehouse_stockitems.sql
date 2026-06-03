CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
    StockItemID INTEGER,
    StockItemName STRING,
    SupplierID INTEGER,
    ColorID INTEGER,
    UnitPackageID INTEGER,
    OuterPackageID INTEGER,
    Brand STRING,
    Size STRING,
    LeadTimeDays INTEGER,
    QuantityPerOuter INTEGER,
    IsChillerStock BOOLEAN,
    Barcode STRING,
    TaxRate NUMERIC(18, 3),
    UnitPrice NUMERIC(18, 2),
    RecommendedRetailPrice NUMERIC(18, 2),
    TypicalWeightPerUnit NUMERIC(18, 3),
    MarketingComments STRING,
    InternalComments STRING,
    Photo BYTES,
    CustomFields STRING,
    Tags STRING,
    SearchDetails STRING,
    LastEditedBy INTEGER,
    ValidFrom DATETIME,
    ValidTo DATETIME, 
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