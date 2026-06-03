CREATE TABLE IF NOT EXISTS << Database >>.<< Schema >>.<< Table >>
(
    StockHoldingKey INTEGER,
    StockItemKey INTEGER,
    QuantityOnHand INTEGER,
    BinLocation STRING,
    LastStocktakeQuantity INTEGER,
    LastCostPrice NUMERIC(18, 2),
    ReorderLevel INTEGER,
    TargetStockLevel INTEGER,
    LoadDate DATETIME
);