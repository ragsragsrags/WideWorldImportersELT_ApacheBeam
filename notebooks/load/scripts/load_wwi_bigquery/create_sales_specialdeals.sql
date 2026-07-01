CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
    SpecialDealID INTEGER,
    StockItemID INTEGER,
    CustomerID INTEGER,
    BuyingGroupID INTEGER,
    CustomerCategoryID INTEGER,
    StockGroupID INTEGER,
    DealDescription STRING,
    StartDate DATE,
    EndDate DATE,
    DiscountAmount NUMERIC(18, 2),
    DiscountPercentage NUMERIC(18, 3),
    UnitPrice NUMERIC(18, 2),
    LastEditedBy INTEGER,
    LastEditedWhen DATETIME,
    LoadDate DATETIME
);