CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
    OrderID INTEGER,
    CustomerID INTEGER,
    SalespersonPersonID INTEGER,
    PickedByPersonID INTEGER,
    ContactPersonID INTEGER,
    BackorderOrderID INTEGER,
    OrderDate DATE,
    ExpectedDeliveryDate DATE,
    CustomerPurchaseOrderNumber STRING,
    IsUndersupplyBackordered BOOLEAN,
    Comments STRING,
    DeliveryInstructions STRING,
    InternalComments STRING,
    PickingCompletedWhen DATETIME,
    LastEditedBy INTEGER,
    LastEditedWhen DATETIME,
    LoadDate DATETIME
);