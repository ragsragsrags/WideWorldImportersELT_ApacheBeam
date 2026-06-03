SELECT
    [CustomerID],
    [CustomerName],
    [BillToCustomerID],
    [CustomerCategoryID],
    [BuyingGroupID],
    [PrimaryContactPersonID],
    [AlternateContactPersonID],
    [DeliveryMethodID],
    [DeliveryCityID],
    [PostalCityID],
    [CreditLimit],
    [AccountOpenedDate],
    [StandardDiscountPercentage],
    [IsStatementSent],
    [IsOnCreditHold],
    [PaymentDays],
    [PhoneNumber],
    [FaxNumber],
    [DeliveryRun],
    [RunPosition],
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
    CustomerID,
    ValidFrom,
    ValidTo

OFFSET 0 ROW