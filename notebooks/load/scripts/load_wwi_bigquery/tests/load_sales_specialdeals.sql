SELECT
    SpecialDealID,
    StockItemID,
    CustomerID,
    BuyingGroupID,
    CustomerCategoryID,
    StockGroupID,
    DealDescription,
    StartDate,
    EndDate,
    DiscountAmount,
    DiscountPercentage,
    UnitPrice,
    LastEditedBy,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LastEditedWhen) AS LastEditedWhen,
    FORMAT_DATETIME('%Y-%m-%d %H:%M:%E6S', LoadDate) AS LoadDate
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    SpecialDealID,
    LastEditedWhen

LIMIT << NumberOfRows >>;