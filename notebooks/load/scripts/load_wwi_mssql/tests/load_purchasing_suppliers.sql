SELECT
    [SupplierID],
    [SupplierName],
    [SupplierCategoryID],
    [PrimaryContactPersonID],
    [AlternateContactPersonID],
    [DeliveryMethodID],
    [DeliveryCityID],
    [PostalCityID],
    [SupplierReference],
    [BankAccountName],
    [BankAccountBranch],
    [BankAccountCode],
    [BankAccountNumber],
    [BankInternationalCode],
    [PaymentDays],
    [InternalComments],
    [PhoneNumber],
    [FaxNumber],
    [WebsiteURL],
    [DeliveryAddressLine1],
    [DeliveryAddressLine2],
    [DeliveryPostalCode],
    [DeliveryLocation] = CAST([DeliveryLocation] AS VARBINARY(MAX)),
    [PostalAddressLine1],
    [PostalAddressLine2],
    [PostalPostalCode],
    [LastEditedBy],
    [ValidFrom],
    [ValidTo],
    [LoadDate]
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    SupplierID,
    ValidFrom,
    ValidTo

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY