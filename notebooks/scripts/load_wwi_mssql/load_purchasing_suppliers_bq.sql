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
    [DeliveryLocation] = [DeliveryLocation].STAsText(),
    [PostalAddressLine1],
    [PostalAddressLine2],
    [PostalPostalCode],
    [LastEditedBy],
    [ValidFrom] = LEFT(CONVERT(NVARCHAR, ValidFrom, 121), 26), 
    [ValidTo] = LEFT(CONVERT(NVARCHAR, ValidTo, 121), 26),
    [LoadDate] = LEFT(CONVERT(NVARCHAR, CAST('<< NewCutoffDate >>' AS DATETIME2(6)), 121), 26)
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    SupplierID,
    ValidFrom,
    ValidTo

OFFSET 0 ROW