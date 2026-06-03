SELECT
    SupplierID,
    SupplierName,
    SupplierCategoryID,
    PrimaryContactPersonID,
    AlternateContactPersonID,
    DeliveryMethodID,
    DeliveryCityID,
    PostalCityID,
    SupplierReference,
    BankAccountName,
    BankAccountBranch,
    BankAccountCode,
    BankAccountNumber,
    BankInternationalCode,
    PaymentDays,
    InternalComments,
    PhoneNumber,
    FaxNumber,
    WebsiteURL,
    DeliveryAddressLine1,
    DeliveryAddressLine2,
    DeliveryPostalCode,
    DeliveryLocation,
    PostalAddressLine1,
    PostalAddressLine2,
    PostalPostalCode,
    LastEditedBy,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', ValidFrom) AS ValidFrom, 
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', ValidTo) AS ValidTo,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LoadDate) AS LoadDate
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    SupplierID,
    ValidFrom,
    ValidTo

LIMIT << NumberOfRows >>;