CREATE TABLE IF NOT EXISTS << Database >>.<< Schema >>.<< Table >>
(
	CustomerKey INTEGER,
	WWICustomerID INTEGER,
	WWIDeliveryCityID INTEGER,
	Customer STRING,
	BillToCustomer STRING,
	Category STRING,
	BuyingGroup STRING,
	PrimaryContact STRING,
	PostalCode STRING,
	IsOnCreditHold BOOLEAN,
	LoadDate DATETIME,
	LastLoadDate DATETIME
);