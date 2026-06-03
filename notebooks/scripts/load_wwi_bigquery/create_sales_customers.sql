CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>` 
(
    CustomerID INTEGER,
    CustomerName STRING,
    BillToCustomerID INTEGER,
    CustomerCategoryID INTEGER,
    BuyingGroupID INTEGER,
    PrimaryContactPersonID INTEGER,
    AlternateContactPersonID INTEGER,
    DeliveryMethodID INTEGER,
    DeliveryCityID INTEGER,
    PostalCityID INTEGER,
    CreditLimit NUMERIC(18, 2),
    AccountOpenedDate DATE,
    StandardDiscountPercentage NUMERIC(18, 3),
    IsStatementSent BOOLEAN,
    IsOnCreditHold BOOLEAN,
    PaymentDays INTEGER,
    PhoneNumber STRING,
    FaxNumber STRING,
    DeliveryRun STRING,
    RunPosition STRING,
    WebsiteURL STRING,
    DeliveryAddressLine1 STRING,
    DeliveryAddressLine2 STRING,
    DeliveryPostalCode STRING,
    DeliveryLocation STRING,
    PostalAddressLine1 STRING,
    PostalAddressLine2 STRING,
    PostalPostalCode STRING,
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