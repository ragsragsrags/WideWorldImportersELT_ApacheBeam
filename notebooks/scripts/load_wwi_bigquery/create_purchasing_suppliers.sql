CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>` 
(
    SupplierID INTEGER,
    SupplierName STRING,
    SupplierCategoryID INTEGER,
    PrimaryContactPersonID INTEGER,
    AlternateContactPersonID INTEGER,
    DeliveryMethodID INTEGER,
    DeliveryCityID INTEGER,
    PostalCityID INTEGER,
    SupplierReference STRING,
    BankAccountName STRING,
    BankAccountBranch STRING,
    BankAccountCode STRING,
    BankAccountNumber STRING,
    BankInternationalCode STRING,
    PaymentDays INTEGER,
    InternalComments STRING,
    PhoneNumber STRING,
    FaxNumber STRING,
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