SELECT
    [SpecialDealID],
    [StockItemID],
    [CustomerID],
    [BuyingGroupID],
    [CustomerCategoryID],
    [StockGroupID],
    [DealDescription],
    [StartDate],
    [EndDate],
    [DiscountAmount],
    [DiscountPercentage],
    [UnitPrice],
    [LastEditedBy],
    [LastEditedWhen], 
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(6))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    SpecialDealID,
    LastEditedWhen

OFFSET 0 ROW