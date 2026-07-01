CREATE TABLE IF NOT EXISTS << Database >>.<< Schema >>.<< Table >>
(
    MovementKey INTEGER,
    DateKey DATE,
    StockItemKey INTEGER,
    CustomerKey INTEGER,
    SupplierKey INTEGER,
    TransactionTypeKey INTEGER,
    WWIStockItemTransactionID INTEGER,
    WWIInvoiceID INTEGER,
    WWIPurchaseOrderID INTEGER,
    Quantity INTEGER,
    LoadDate DATETIME,
    LastLoadDate DATETIME
);