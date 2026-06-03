CREATE TABLE IF NOT EXISTS << Database >>.<< Schema >>.<< Table >>
(
    OrderKey INTEGER,
    CityKey INTEGER,
    CustomerKey INTEGER,
    StockItemKey INTEGER,
    OrderDateKey DATE,
    PickedDateKey DATE,
    SalesPersonKey INTEGER,
    PickerKey INTEGER,
    WWIOrderID INTEGER,
    WWIOrderLineID INTEGER,
    WWIBackorderID INTEGER,
    Description STRING,
    Package STRING,
    Quantity INTEGER,
    UnitPrice NUMERIC(18, 2),
    TaxRate NUMERIC(18, 3),
    TotalExcludingTax NUMERIC(18, 2),
    TaxAmount NUMERIC(18, 2),
    TotalIncludingTax NUMERIC(18, 2),
    LoadDate DATETIME
);