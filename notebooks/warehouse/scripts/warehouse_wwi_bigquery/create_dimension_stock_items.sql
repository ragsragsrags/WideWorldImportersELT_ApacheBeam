CREATE TABLE IF NOT EXISTS << Database >>.<< Schema >>.<< Table >>
(
    StockItemKey INTEGER,
    WWIStockItemID INTEGER,
    StockItem STRING,
    Color STRING,
    SellingPackage STRING,
    BuyingPackage STRING,
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
    Photo BYTES,
    LoadDate DATETIME,
    LastLoadDate DATETIME
);