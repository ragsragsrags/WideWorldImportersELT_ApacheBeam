CREATE TABLE IF NOT EXISTS << Database >>.<< Schema >>.<< Table >>
(
    PurchaseKey INTEGER,
    DateKey DATE,
    SupplierKey INTEGER,
    StockItemKey INTEGER,
    WWIPurchaseOrderID INTEGER,
    WWIPurchaseOrderLineID INTEGER,
    OrderedOuters INTEGER,
    OrderedQuantity INTEGER,
    ReceivedOuters INTEGER,
    Package STRING,
    IsOrderFinalized BOOLEAN,
    LoadDate DATETIME,
    LastLoadDate DATETIME
);