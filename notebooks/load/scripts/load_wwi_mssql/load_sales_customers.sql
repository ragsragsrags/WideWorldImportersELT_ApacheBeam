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
    [DeliveryLocation] = CAST([DeliveryLocation] AS VARBINARY(MAX)),
    [PostalAddressLine1],
    [PostalAddressLine2],
    [PostalPostalCode],
    [LastEditedBy],
    [ValidFrom],
    [ValidTo],
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(6))
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